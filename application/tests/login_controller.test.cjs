const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const sdkHome = process.env.DEVECO_SDK_HOME || '/Applications/DevEco-Studio.app/Contents/sdk';
const ts = require(path.join(sdkHome, 'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
const source = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/login/LoginController.ets'), 'utf8');
const output = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}
function fixture() {
  const storage = new Map();
  const login = deferred();
  const signature = deferred();
  const writes = [];
  const states = [];
  const timers = new Map();
  let loginCalls = 0;
  let listener;
  let now = 0;
  const sdk = {
    state: {},
    login: () => { loginCalls++; return login.promise; },
    logout: () => Promise.resolve(),
    setSelfInfo: profile => {
      const request = deferred();
      writes.push({ profile, request });
      return request.promise;
    },
    loginEventEmitter: { subscribe: (owner, fn) => { listener = fn; return () => listener = undefined; } }
  };
  const prefs = {
    getSync: (key, fallback) => storage.has(key) ? storage.get(key) : fallback,
    putSync: (key, value) => storage.set(key, value),
    deleteSync: key => storage.delete(key),
    flush: () => {}
  };
  const api = { LoginEvent: { KICKED_OFFLINE: 1, LOGIN_EXPIRED: 2 }, LoginStore: { shared: () => sdk }, UserProfile: class {} };
  const context = {
    exports: {}, Date: { now: () => now },
    $r: name => ({ id: name }),
    setInterval: fn => { const id = timers.size + 1; timers.set(id, fn); return id; },
    clearInterval: id => timers.delete(id),
    require: name => {
      if (name === '@kit.ArkData') return { preferences: { getPreferencesSync: () => prefs } };
      if (name === '@tencentcloud/atomicxcore') return api;
      if (name.endsWith('/GenerateTestUserSig')) return { GenerateTestUserSig: { SDKAPPID: 1, genTestUserSig: () => signature.promise } };
      throw new Error(name);
    }
  };
  vm.runInNewContext(output, context);
  const controller = new context.exports.LoginController();
  controller.onChanged = (phase, loading, error) => states.push({ phase, loading, error });
  controller.attach({ resourceManager: { getStringSync: id => id } });
  return { controller, sdk, signature, login, writes, storage, states, timers,
    phases: context.exports.LoginPhase, loginCalls: () => loginCalls,
    event: event => listener?.(event), tick: () => [...timers.values()].forEach(fn => fn()),
    advance: value => now = value };
}
const flush = () => new Promise(setImmediate);
(async () => {
  const f = fixture();
  const task = f.controller.login(' alice ');
  await f.controller.login('bob');
  f.signature.resolve('signature');
  await flush();
  assert.equal(f.loginCalls(), 1, 'only one SDK login request is allowed');
  f.sdk.state.loginUserInfo = { userID: 'old', nickname: 'Old' };
  f.login.resolve();
  await task;
  f.tick();
  assert.notEqual(f.states.at(-1).phase, f.phases.home, 'a stale profile cannot complete a new login');
  f.sdk.state.loginUserInfo = { userID: 'alice', nickname: 'Alice' };
  f.tick();
  assert.equal(f.states.at(-1).phase, f.phases.home);
  assert.equal(f.storage.get('userID'), 'alice');
  assert.equal(f.timers.size, 0);
  f.controller.setAutomatic(true);
  await f.controller.logout();
  assert.equal(f.storage.has('userID'), false);
  assert.equal(f.storage.get('automatic'), true);
  assert.equal(f.states.at(-1).phase, f.phases.login);

  const detached = fixture();
  const detachedTask = detached.controller.login('alice');
  detached.controller.detach();
  detached.signature.resolve('signature');
  await detachedTask;
  assert.equal(detached.loginCalls(), 0, 'late signature must not start SDK login after detach');

  const kicked = fixture();
  const kickedTask = kicked.controller.login('alice');
  kicked.signature.resolve('signature');
  await flush();
  kicked.event(1);
  kicked.sdk.state.loginUserInfo = { userID: 'alice', nickname: 'Alice' };
  kicked.login.resolve();
  await kickedTask;
  assert.equal(kicked.states.at(-1).phase, kicked.phases.login);
  assert.equal(kicked.states.at(-1).loading, false);
  assert.equal(kicked.timers.size, 0, 'invalidated login must not create a profile wait');

  const timed = fixture();
  const timedTask = timed.controller.login('alice');
  timed.signature.resolve('signature');
  timed.login.resolve();
  await timedTask;
  timed.advance(5001);
  timed.tick();
  assert.equal(timed.states.at(-1).loading, false);
  assert.equal(timed.timers.size, 0);
  assert.match(timed.states.at(-1).error, /profile_timeout/);

  const registration = fixture();
  const registerLogin = registration.controller.login('alice');
  registration.signature.resolve('signature');
  registration.sdk.state.loginUserInfo = { userID: 'alice', nickname: '' };
  registration.login.resolve();
  await registerLogin;
  registration.tick();
  assert.equal(registration.states.at(-1).phase, registration.phases.register);
  const save = registration.controller.register('Alice');
  await registration.controller.register('Duplicate');
  assert.equal(registration.writes.length, 1);
  registration.writes[0].request.reject(new Error('offline'));
  await save;
  assert.equal(registration.states.at(-1).phase, registration.phases.register);
  assert.equal(registration.states.at(-1).error, 'offline');
  const retry = registration.controller.register('Alice');
  registration.writes[1].request.resolve();
  await retry;
  assert.equal(registration.states.at(-1).phase, registration.phases.home);
  await registration.controller.login('another');
  assert.equal(registration.loginCalls(), 1, 'home ignores stale login actions');
  await registration.controller.register('Unexpected');
  assert.equal(registration.writes.length, 2, 'home ignores stale registration actions');

  const cancelled = fixture();
  const cancelledLogin = cancelled.controller.login('alice');
  cancelled.signature.resolve('signature');
  cancelled.sdk.state.loginUserInfo = { userID: 'alice', nickname: '' };
  cancelled.login.resolve();
  await cancelledLogin;
  cancelled.tick();
  const cancelledSave = cancelled.controller.register('Alice');
  cancelled.controller.cancelRegistration();
  assert.equal(cancelled.states.at(-1).phase, cancelled.phases.login);
  assert.equal(cancelled.states.at(-1).loading, false);
  cancelled.writes[0].request.resolve();
  await cancelledSave;
  assert.equal(cancelled.states.at(-1).phase, cancelled.phases.login, 'late registration cannot reopen home after back');
  console.log('PASS: registration cancellation and phase guards; login deduplication, profile identity, cache logout, detach, invalidation, timeout, registration retry');
})().catch(error => { console.error(error); process.exitCode = 1; });

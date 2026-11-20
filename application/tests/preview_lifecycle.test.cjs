const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const sdkHome = process.env.DEVECO_SDK_HOME || '/Applications/DevEco-Studio.app/Contents/sdk';
const ts = require(path.join(sdkHome, 'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
// Execute the production lifecycle methods without ArkUI rendering or a device.
let source = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/live/home/LiveHomePreviewView.ets'), 'utf8');
// Optimised @Observed objects reject UI reads of fields without @Track, including ForEach keys.
const itemSource = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/live/home/LiveHomePreviewItemView.ets'), 'utf8');
const sessionSource = source.slice(source.indexOf('export class LiveHomePlaybackSession'), source.indexOf('@Component'));
const trackedFields = new Set([...sessionSource.matchAll(/@Track\s+(?:readonly\s+)?(\w+)/g)].map(match => match[1]));
const uiSource = itemSource.slice(itemSource.indexOf('  build() {'));
for (const match of uiSource.matchAll(/this\.session\.(\w+)/g)) {
  assert.ok(trackedFields.has(match[1]), `UI reads non-tracked session field: ${match[1]}`);
}
source = source.slice(0, source.indexOf('\n  build() {')) + '\n}\n';
source = source.replace(/export struct LiveHomePreviewView/, 'export class LiveHomePreviewView');
source = source.replace(/@(Observed|Component|Track|State|Prop|Watch|StorageProp)(?:\([^)]*\))?\s*/g, '');
const output = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
const statuses = { idle: 0, playing: 1, inRoom: 2, coGuest: 3, end: 4 };
let sequence = 0;
class Player {
  listeners = new Set();
  current = statuses.idle;
  volume = 0;
  leaves = 0;
  stops = 0;
  joins = 0;
  setLiveInfo(info) { this.info = info; }
  status(fn) { this.listeners.add(fn); fn(this.current); return () => this.listeners.delete(fn); }
  emit(value) { this.current = value; this.listeners.forEach(fn => fn(value)); }
  setVolume(value) { this.volume = value; }
  startPlay() { if (this.current === statuses.idle) this.emit(statuses.playing); }
  stopPlay() { this.stops++; if (this.current === statuses.playing) this.emit(statuses.idle); }
  leaveChannel() { this.leaves++; if (this.current === statuses.inRoom) this.emit(statuses.playing); return Promise.resolve(); }
  joinChannel() {
    this.joins++;
    return new Promise(resolve => this.completeJoin = () => { this.emit(statuses.inRoom); resolve(this.info); });
  }
}
class State { items = []; revision = 0; }
class Store { state = new State(); loadMore() {} }
const context = {
  exports: {},
  require: name => {
    if (name === '@kit.ArkUI') return { promptAction: { showToast() {} } };
    if (name === '@kit.ArkTS') return { util: { generateRandomUUID: () => String(++sequence) } };
    if (name === 'tuilivekit') return { PlayerStatus: statuses, PlayerViewController: Player };
    if (name === '@tencentcloud/atomicxcore') return { LoginStore: { shared: () => ({ state: {} }) } };
    if (name === './LiveHomeListStore') return { LiveHomeListState: State, LiveHomeListStore: Store };
    throw new Error(name);
  }
};
vm.runInNewContext(output, context);
const View = context.exports.LiveHomePreviewView;
const flush = () => new Promise(setImmediate);
(async () => {
  const view = new View();
  view.active = true;
  view.state.items = Array.from({ length: 5 }, (_, i) => ({ liveID: String(i), liveOwner: { userID: 'host' } }));
  view.aboutToAppear();
  const sessions = view.state.items.slice(0, 4).map(info => view.session(info));
  sessions.forEach(session => view.mounted(session));
  assert.ok(sessions[0].controller);
  assert.ok(sessions[1].controller);
  assert.equal(sessions[2].controller, undefined, 'a far prefetched row must not create an SDK player');
  const firstController = sessions[0].controller;
  const firstKey = sessions[0].renderKey;
  view.currentIndex = 1;
  view.updatePlayback();
  assert.ok(sessions[2].controller, 'a mounted prefetch row activates when it becomes adjacent');
  assert.equal(sessions[0].controller, firstController, 'adjacent playback keeps its SDK instance');
  view.currentIndex = 2;
  view.updatePlayback();
  assert.equal(sessions[0].controller, undefined);
  assert.equal(firstController.listeners.size, 0);
  assert.ok(sessions[3].controller);
  assert.equal(sessions.filter(session => session.controller !== undefined).length, 3);
  assert.equal(sessions[2].controller.volume, 100);
  assert.equal(sessions[1].controller.volume, 0);
  view.currentIndex = 0;
  view.updatePlayback();
  assert.notEqual(sessions[0].controller, firstController);
  assert.ok(sessions[0].renderKey > firstKey, 'a replacement controller must use a new render identity');

  view.currentIndex = 2;
  view.automatic = true;
  view.updatePlayback();
  const joining = sessions[2].controller;
  assert.equal(joining.joins, 1);
  view.active = false;
  view.updatePlayback();
  assert.equal(sessions.filter(session => session.controller !== undefined).length, 0);
  view.active = true;
  view.updatePlayback();
  const replacement = sessions[2].controller;
  assert.notEqual(replacement, joining);
  assert.equal(replacement.joins, 0, 'new join waits for the retiring join');
  joining.completeJoin();
  await flush();
  assert.ok(joining.leaves > 0, 'late success cleans up the controller that issued it');
  assert.equal(replacement.leaves, 0, 'late success must not leave the replacement player');
  assert.equal(replacement.joins, 1);
  replacement.completeJoin();
  await flush();
  assert.equal(view.pending, 0);
  assert.equal(view.firstJoined, true);
  const updated = { liveID: '2', liveName: 'updated', liveOwner: { userID: 'host' } };
  view.state.items[2] = updated;
  view.state.revision++;
  view.rowsChanged();
  assert.equal(sessions[2].info, updated);
  assert.equal(replacement.info, updated);
  view.aboutToDisappear();
  sessions.forEach(session => assert.equal(session.controller, undefined));
  assert.equal(view.sessions.size, 0);
  const direct = new View();
  direct.direct = true;
  direct.active = true;
  direct.state.items = [{ liveID: 'direct', liveOwner: { userID: 'host' } }];
  let closeCount = 0;
  const joiningEvents = [];
  direct.onClose = () => closeCount++;
  direct.onJoining = value => joiningEvents.push(value);
  direct.aboutToAppear();
  const directSession = direct.session(direct.state.items[0]);
  direct.mounted(directSession);
  const cancelledPlayer = directSession.controller;
  assert.equal(direct.pending, 1);
  direct.closeCurrent();
  direct.closeCurrent();
  assert.equal(closeCount, 1, 'direct join cancellation closes exactly once');
  assert.equal(directSession.controller, undefined);
  direct.updatePlayback();
  assert.equal(directSession.controller, undefined, 'closing cannot recreate a player');
  cancelledPlayer.completeJoin();
  await flush();
  assert.equal(direct.pending, 0);
  assert.equal(joiningEvents.at(-1), false, 'retired join eventually unlocks its parent');
  assert.equal(direct.firstJoined, false, 'late join cannot enter a closed room');
  assert.ok(cancelledPlayer.leaves >= 2, 'late join success cleans up the cancelled player');
  direct.aboutToDisappear();
  console.log('PASS: UI tracked-field contract; pending direct join cancellation; nearest-three allocation, prefetch activation, stable controller, render identity, retired-join isolation, metadata update, cleanup');
})().catch(error => { console.error(error); process.exitCode = 1; });

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const sdkHome = process.env.DEVECO_SDK_HOME || '/Applications/DevEco-Studio.app/Contents/sdk';
const ts = require(path.join(sdkHome, 'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
class DataSource {
  data = [];
  setData(data) { this.data = data; }
  getAllData() { return this.data; }
}
class LiveInfo {
  categoryList = [];
  metaData = new Map();
}
class LiveUserInfo {}
const requests = [];
const sdk = {
  liveState: { liveList: new DataSource(), liveListCursor: '' },
  fetchLiveList(cursor, count) {
    return new Promise((resolve, reject) => requests.push({ cursor, count, resolve, reject }));
  }
};
const api = { BasicDataSource: DataSource, LiveInfo, LiveUserInfo, LiveListStore: { shared: () => sdk } };
const source = fs.readFileSync(path.join(__dirname, '../entry/src/main/ets/live/home/LiveHomeListStore.ets'), 'utf8');
const output = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
const context = { exports: {}, require: name => { assert.equal(name, '@tencentcloud/atomicxcore'); return api; } };
vm.runInNewContext(output, context);
const Store = context.exports.LiveHomeListStore;
function live(id, title = id) {
  const info = new LiveInfo();
  info.liveID = id;
  info.liveName = title;
  info.liveOwner = Object.assign(new LiveUserInfo(), { userID: id, userName: title, avatarURL: '', level: 0 });
  return info;
}
async function resolve(request, items, cursor) {
  sdk.liveState.liveList.setData(items);
  sdk.liveState.liveListCursor = cursor;
  request.resolve();
  await new Promise(setImmediate);
}
(async () => {
  const store = new Store();
  store.refresh();
  assert.equal(store.state.refreshing, true);
  store.refresh();
  assert.equal(requests.length, 1, 'duplicate refresh is blocked');
  const original = live('a');
  await resolve(requests.shift(), [original, live('a', 'updated'), live('b')], 'next');
  assert.equal(store.state.items.length, 2);
  assert.equal(store.state.items[0].liveName, 'updated');
  const copy = store.independentCopy();
  copy.loadMore();
  assert.equal(copy.state.refreshing, false, 'pagination must not drive the refresh control');
  const more = requests.shift();
  assert.equal(more.cursor, 'next');
  await resolve(more, [live('c')], 'third');
  assert.equal(copy.state.items.length, 3);
  assert.equal(store.state.items.length, 2, 'independent feed cannot mutate home rows');
  store.loadMore();
  const homeMore = requests.shift();
  assert.equal(homeMore.cursor, 'next', 'independent feed cannot advance home cursor');
  await resolve(homeMore, [original], '');
  original.liveName = 'mutated SDK title';
  assert.equal(store.state.items[0].liveName, 'a', 'SDK object updates do not mutate projected rows');
  assert.equal(copy.state.items[0].liveName, 'updated');
  assert.equal(store.state.hasMore, false);
  store.refresh();
  const stale = requests.shift();
  store.setActive(false);
  store.setActive(true);
  store.refresh();
  const current = requests.shift();
  await resolve(current, [live('new')], '');
  await resolve(stale, [live('old')], 'bad');
  assert.equal(store.state.items[0].liveID, 'new', 'offscreen request cannot overwrite a newer response');
  store.refresh();
  requests.shift().reject(new Error('offline'));
  await new Promise(setImmediate);
  assert.equal(store.state.error, 'offline');
  assert.equal(store.state.items[0].liveID, 'new', 'failed refresh preserves the visible snapshot');
  store.retry();
  assert.equal(requests.shift().cursor, '');
  console.log('PASS: request deduplication, row merging, independent cursors, detached snapshots, stale-response filtering, retry');
})().catch(error => { console.error(error); process.exitCode = 1; });

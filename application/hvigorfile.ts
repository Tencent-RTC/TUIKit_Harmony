import { hvigor } from '@ohos/hvigor';
import { appTasks, OhosAppContext, OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import * as fs from 'fs';
import * as path from 'path';

type AppProfile = ReturnType<OhosAppContext['getBuildProfileOpt']>;

interface LocalSigning {
  signingConfigs: NonNullable<AppProfile['app']['signingConfigs']>;
  products: Record<string, string>;
}

hvigor.afterNodeEvaluate(node => {
  const context = node.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext | undefined;
  if (!context) {
    return;
  }
  const profile = context.getBuildProfileOpt();
  if (process.env.HARMONY_UNSIGNED === '1') {
    profile.app.signingConfigs = [];
    profile.app.products?.forEach(product => { delete product.signingConfig; });
    context.setBuildProfileOpt(profile);
    return;
  }
  const shared = profile.app.signingConfigs ?? [];
  let localProducts: Record<string, string> = {};
  const localPath = path.join(context.getProjectPath(), 'signing.local.json');
  if (fs.existsSync(localPath)) {
    const local = JSON.parse(fs.readFileSync(localPath, 'utf8')) as LocalSigning;
    if (!Array.isArray(local.signingConfigs) || !local.products) {
      throw new Error('signing.local.json must contain signingConfigs and products. See README.md.');
    }
    localProducts = local.products;
    profile.app.signingConfigs = shared.concat(local.signingConfigs.filter(config =>
      !shared.some(existing => existing.name === config.name)));
  }
  const signingConfigs = profile.app.signingConfigs ?? [];
  if (signingConfigs.length === 0) {
    return;
  }
  profile.app.products?.forEach(product => {
    const signingName = product.signingConfig ??
      shared.find(config => config.name === localProducts[product.name])?.name ??
      shared[0]?.name ??
      localProducts[product.name];
    if (signingName) {
      if (!signingConfigs.some(config => config.name === signingName)) {
        throw new Error(`No signing configuration found for product ${product.name}.`);
      }
      product.signingConfig = signingName;
    }
  });
  context.setBuildProfileOpt(profile);
});

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
};

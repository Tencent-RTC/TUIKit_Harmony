export class RoomResources {
  static image(name: string): Resource {
    const resource: Resource = { bundleName: '', moduleName: '', id: -1, params: [`app.media.${name}`], type: 20000 }
    return resource
  }

  static string(name: string, ...args: (string | number)[]): string {
    const key = name.replace(/[.-]/g, '_')
    try {
      return getContext().resourceManager.getStringByNameSync(key, ...args)
    } catch (error) {
      return key
    }
  }
}

export class AsrServiceError {
  static readonly SERVICE_UNAVAILABLE: number = 140008;

  static isServiceUnavailable(code: number): boolean {
    return code === AsrServiceError.SERVICE_UNAVAILABLE;
  }
}

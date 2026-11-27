export default abstract class BasicData {
    ID: string;
    getKey(): string;
    protected getStateHash(): string;
}

/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AITranscriberStore @ AtomicXCore
 * Function: AI real-time transcription related interfaces, managing real-time speech-to-text transcription and translation features.
 */
/**
 * Source language type for transcription recognition.
 *
 * Defines the source language for speech recognition during real-time transcription. The transcriber will recognize speech in the specified source language and convert it to text.
 *
 * > **Tip**: Choose the source language that matches the speaker's language for best recognition accuracy. Use `CHINESE_ENGLISH` for mixed Chinese and English scenarios.
 *
 * ### Source Language List
 *
 * | Language | Value | Description |
 * |--------|------|-----------|
 * | [CHINESE_ENGLISH] | zh_en | Chinese-English mixed |
 * | [CHINESE] | zh | Chinese |
 * | [ENGLISH] | en | English |
 * | [CANTONESE] | zh-yue | Cantonese |
 * | [VIETNAMESE] | vi | Vietnamese |
 * | [JAPANESE] | ja | Japanese |
 * | [KOREAN] | ko | Korean |
 * | [INDONESIAN] | id | Indonesian |
 * | [THAI] | th | Thai |
 * | [PORTUGUESE] | pt | Portuguese |
 * | [TURKISH] | tr | Turkish |
 * | [ARABIC] | ar | Arabic |
 * | [SPANISH] | es | Spanish |
 * | [HINDI] | hi | Hindi |
 * | [FRENCH] | fr | French |
 * | [MALAY] | ms | Malay |
 * | [FILIPINO] | fil | Filipino |
 * | [GERMAN] | de | German |
 * | [ITALIAN] | it | Italian |
 * | [RUSSIAN] | ru | Russian |
 */
export declare enum SourceLanguage {
    /**
     * Chinese-English mixed recognition.
     */
    CHINESE_ENGLISH = "zh_en",
    /**
     * Chinese.
     */
    CHINESE = "zh",
    /**
     * English.
     */
    ENGLISH = "en",
    /**
     * Cantonese.
     */
    CANTONESE = "zh-yue",
    /**
     * Vietnamese.
     */
    VIETNAMESE = "vi",
    /**
     * Japanese.
     */
    JAPANESE = "ja",
    /**
     * Korean.
     */
    KOREAN = "ko",
    /**
     * Indonesian.
     */
    INDONESIAN = "id",
    /**
     * Thai.
     */
    THAI = "th",
    /**
     * Portuguese.
     */
    PORTUGUESE = "pt",
    /**
     * Turkish.
     */
    TURKISH = "tr",
    /**
     * Arabic.
     */
    ARABIC = "ar",
    /**
     * Spanish.
     */
    SPANISH = "es",
    /**
     * Hindi.
     */
    HINDI = "hi",
    /**
     * French.
     */
    FRENCH = "fr",
    /**
     * Malay.
     */
    MALAY = "ms",
    /**
     * Filipino.
     */
    FILIPINO = "fil",
    /**
     * German.
     */
    GERMAN = "de",
    /**
     * Italian.
     */
    ITALIAN = "it",
    /**
     * Russian.
     */
    RUSSIAN = "ru"
}
/**
 * Target language type for translation.
 *
 * Defines the target language for translation during real-time transcription. The transcriber will translate recognized text into the specified target languages.
 *
 * > **Tip**: Multiple translation languages can be configured simultaneously. The translation results will be stored in the `translationTexts` map of `TranscriberMessage`.
 *
 * ### Translation Language List
 *
 * | Language | Value | Description |
 * |--------|------|-----------|
 * | [CHINESE] | zh | Chinese |
 * | [ENGLISH] | en | English |
 * | [VIETNAMESE] | vi | Vietnamese |
 * | [JAPANESE] | ja | Japanese |
 * | [KOREAN] | ko | Korean |
 * | [INDONESIAN] | id | Indonesian |
 * | [THAI] | th | Thai |
 * | [PORTUGUESE] | pt | Portuguese |
 * | [ARABIC] | ar | Arabic |
 * | [SPANISH] | es | Spanish |
 * | [FRENCH] | fr | French |
 * | [MALAY] | ms | Malay |
 * | [GERMAN] | de | German |
 * | [ITALIAN] | it | Italian |
 * | [RUSSIAN] | ru | Russian |
 */
export declare enum TranslationLanguage {
    /**
     * Chinese.
     */
    CHINESE = "zh",
    /**
     * English.
     */
    ENGLISH = "en",
    /**
     * Vietnamese.
     */
    VIETNAMESE = "vi",
    /**
     * Japanese.
     */
    JAPANESE = "ja",
    /**
     * Korean.
     */
    KOREAN = "ko",
    /**
     * Indonesian.
     */
    INDONESIAN = "id",
    /**
     * Thai.
     */
    THAI = "th",
    /**
     * Portuguese.
     */
    PORTUGUESE = "pt",
    /**
     * Arabic.
     */
    ARABIC = "ar",
    /**
     * Spanish.
     */
    SPANISH = "es",
    /**
     * French.
     */
    FRENCH = "fr",
    /**
     * Malay.
     */
    MALAY = "ms",
    /**
     * German.
     */
    GERMAN = "de",
    /**
     * Italian.
     */
    ITALIAN = "it",
    /**
     * Russian.
     */
    RUSSIAN = "ru"
}
/**
 * Voice type for interpretation.
 */
export declare enum InterpretationVoice {
    /**
     * Female voice.
     */
    FEMALE = "female",
    /**
     * Male voice.
     */
    MALE = "male"
}
/**
 * Transcription message, representing a single segment of transcribed speech.
 *
 * Represents a single segment of transcribed speech, containing the original text, translation texts, speaker information, and completion status.
 * Each message corresponds to a continuous speech segment from a speaker.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [segmentId] | `string` | Unique identifier of the transcription segment |
 * | [speakerUserId] | `string` | User ID of the speaker |
 * | [speakerUserName] | `string` | Display name of the speaker |
 * | [sourceText] | `string` | Original transcribed text |
 * | [translationTexts] | `Map<TranslationLanguage, string>` | Translation results, keyed by target language |
 * | [timestamp] | `number` | Timestamp of the message |
 * | [isCompleted] | `boolean` | Whether the segment transcription is completed |
 *
 * > **Tip**: A message with [isCompleted] set to `true` indicates that the speaker has finished this segment of speech. The `sourceText` and `translationTexts` will no longer be updated for completed messages.
 */
@Observed
export declare class TranscriberMessage {
    /**
     * Unique identifier of the transcription segment.
     */
    segmentId: string;
    /**
     * User ID of the speaker.
     */
    speakerUserId: string;
    /**
     * Display name of the speaker.
     */
    speakerUserName: string;
    /**
     * Original transcribed text from the speech recognition.
     */
    sourceText: string;
    /**
     * Translation results, keyed by target language. Contains translation texts for each configured translation language.
     */
    translationTexts: Map<TranslationLanguage, string>;
    /**
     * Timestamp of the message.
     */
    timestamp: number;
    /**
     * Whether the segment transcription is completed. When `true`, the source text and translation texts will no longer be updated.
     */
    isCompleted: boolean;
    constructor(segmentId?: string, speakerUserId?: string, speakerUserName?: string, sourceText?: string, translationTexts?: Map<TranslationLanguage, string>, timestamp?: number, isCompleted?: boolean);
}
/**
 * Configuration for transcription features.
 *
 * Configuration for the transcription feature, including whether to enable translation.
 */
export declare class TranscriptionConfig {
    /**
     * Whether to enable translation during transcription.
     */
    enableTranslation: boolean;
    constructor(enableTranslation?: boolean);
}
/**
 * Configuration for interpretation features.
 *
 * Configuration for the interpretation feature, including voice type selection.
 */
export declare class InterpretationConfig {
    /**
     * Voice type for interpretation output.
     */
    voice: InterpretationVoice;
    constructor(voice?: InterpretationVoice);
}
/**
 * Transcription configuration, used to configure source language and translation languages.
 *
 * Configuration for real-time transcription, including the source language for speech recognition and the target languages for translation.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [sourceLanguage] | `SourceLanguage` | Source language for speech recognition, defaults to Chinese-English mixed |
 * | [translationLanguages] | `List<TranslationLanguage>` | List of target languages for translation |
 *
 * @deprecated Use TranscriptionConfig or InterpretationConfig instead
 */
export declare class TranscriberConfig {
    /**
     * Source language for speech recognition, defaults to Chinese-English mixed.
     */
    sourceLanguage: SourceLanguage;
    /**
     * List of target languages for translation. Multiple languages can be configured simultaneously.
     */
    translationLanguages: TranslationLanguage[];
    constructor(sourceLanguage?: SourceLanguage, translationLanguages?: TranslationLanguage[]);
}
/**
 * Transcription state data provided by AITranscriberStore.
 *
 * Contains the real-time transcription state. Subscribe to this state to display transcription results in the UI.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [selfLanguage] | `SourceLanguage` | Current user's self language |
 * | [realtimeMessageList] | `TranscriberMessage[]` | List of real-time transcription messages |
 * | [isTranscriptionRunning] | `boolean` | Whether transcription is running |
 * | [transcriptionConfig] | `TranscriptionConfig` | Current transcription configuration |
 * | [isInterpretationRunning] | `boolean` | Whether interpretation is running |
 * | [interpretationConfig] | `InterpretationConfig` | Current interpretation configuration |
 * | [interpretationVolume] | `number` | Current interpretation volume |
 *
 * > **Tip**: The message list is updated automatically as transcription progresses. Subscribe to [transcriberState] to receive real-time updates.
 */
@Observed
export declare class TranscriberState {
    /**
     * Current user's self language.
     */
    selfLanguage: SourceLanguage;
    /**
     * List of real-time transcription messages, updated automatically as transcription progresses.
     */
    realtimeMessageList: TranscriberMessage[];
    /**
     * Whether transcription is currently running.
     */
    isTranscriptionRunning: boolean;
    /**
     * Current transcription configuration.
     */
    transcriptionConfig: TranscriptionConfig;
    /**
     * Whether interpretation is currently running.
     */
    isInterpretationRunning: boolean;
    /**
     * Current interpretation configuration.
     */
    interpretationConfig: InterpretationConfig;
    /**
     * Current interpretation volume level.
     */
    interpretationVolume: number;
}
/**
 * AI transcriber event callback.
 *
 * @deprecated Use transcriberState to observe state changes instead
 */
export declare class AITranscriberStoreListener {
    /**
     * Triggered when a new transcription message is received.
     *
     * @param roomID Room ID.
     * @param message The transcription message containing recognized text, translation results, and speaker information.
     */
    onReceiveTranscriberMessage?: (roomID: string, message: TranscriberMessage) => void;
    /**
     * Triggered when the real-time transcription service has been started successfully.
     *
     * @param roomID Room ID.
     * @param transcriberRobotID Transcriber robot ID.
     */
    onRealtimeTranscriberStarted?: (roomID: string, transcriberRobotID: string) => void;
    /**
     * Triggered when the real-time transcription service has been stopped.
     *
     * @param roomID Room ID.
     * @param transcriberRobotID Transcriber robot ID.
     * @param reason Stop reason code. - 0: User proactively stopped the transcription task. - 1: Room was dissolved by the server. - 2: All users involved in transcription left the room for more than 30 seconds, causing the task to end automatically.
     */
    onRealtimeTranscriberStopped?: (roomID: string, transcriberRobotID: string, reason: number) => void;
    /**
     * Triggered when an error occurs during real-time transcription.
     *
     * @param roomID Room ID.
     * @param transcriberRobotID Transcriber robot ID.
     * @param code Error code.
     * @param message Error message description.
     */
    onRealtimeTranscriberError?: (roomID: string, transcriberRobotID: string, code: number, message: string) => void;
}
/**
 * AI real-time transcription related interfaces, managing real-time speech-to-text transcription and translation features.
 *
 * `AITranscriberStore` AI real-time transcription management class for handling speech-to-text transcription and translation business.
 * `AITranscriberStore` provides a complete set of AI real-time transcription management APIs, including starting, updating, and stopping real-time transcription.
 * Through this class, you can implement real-time speech-to-text transcription with multi-language translation support during audio/video calls or live streaming.
 *
 * ### Key Features
 *
 * - **Real-time Transcription**: Supports real-time speech-to-text transcription during audio/video sessions.
 * - **Multi-language Source**: Supports 20 source languages including Chinese, English, Japanese, Korean, etc.
 * - **Real-time Translation**: Supports translating transcribed text into 15 target languages in real-time.
 * - **State Management**: Provides real-time message list state for UI display.
 *
 * > **Important**: Use the [AITranscriberStore.create] factory method to create an `AITranscriberStore` instance for a specific room. Configure the source language and translation languages before starting transcription.
 *
 * > **Tip**: Transcription state updates are delivered through the [transcriberState] publisher. Subscribe to it to receive real-time transcription messages.
 *
 * ### Getting Instance
 * - [AITranscriberStore.create] - Create an instance for a specific room.
 *
 * ### Observing State and Events
 * - [transcriberState] - Transcriber state data.
 *
 * ### Transcription Control
 * - [startTranscription] - Start transcription.
 * - [updateTranscription] - Update transcription configuration.
 * - [stopTranscription] - Stop transcription.
 *
 * ### Interpretation Control
 * - [startInterpretation] - Start interpretation.
 * - [updateInterpretation] - Update interpretation configuration.
 * - [stopInterpretation] - Stop interpretation.
 * - [setInterpretationVolume] - Set interpretation volume.
 *
 * @see [SourceLanguage]
 * @see [TranslationLanguage]
 * @see [InterpretationVoice]
 * @see [TranscriberMessage]
 * @see [TranscriptionConfig]
 * @see [InterpretationConfig]
 * @see [TranscriberState]
 */
@Observed
export declare class AITranscriberStore {
    private static instances;
    private impl;
    private constructor();
    /**
     * Create an AITranscriberStore instance for a specific room.
     *
     * @param roomID Room ID.
     * @returns AITranscriberStore instance.
     */
    static create(roomID: string): AITranscriberStore;
    /**
     * Transcriber state data.
     */
    get transcriberState(): Readonly<TranscriberState>;
    /**
     * Add AI transcriber event callback listener
     *
     * @deprecated Use transcriberState to observe state changes instead
     */
    addAITranscriberListener(listener: AITranscriberStoreListener): void;
    /**
     * Remove AI transcriber event callback listener
     *
     * @deprecated Use transcriberState to observe state changes instead
     */
    removeAITranscriberListener(listener: AITranscriberStoreListener): void;
    /**
     * Start transcription
     *
     * Start the AI transcription service with the specified language and configuration.
     * Once started, the transcriber will recognize speech in the room and provide real-time transcription results through the state publisher.
     *
     * @param myLanguage The source language for the current user's speech recognition.
     * @param config Transcription configuration, including whether to enable translation.
     */
    startTranscription(myLanguage: SourceLanguage, config?: TranscriptionConfig): Promise<void>;
    /**
     * Update transcription configuration
     *
     * Update the configuration of the ongoing transcription service.
     * This can be used to change the source language or modify the translation settings without stopping and restarting the transcription.
     *
     * @param myLanguage The new source language for speech recognition.
     * @param config New transcription configuration.
     */
    updateTranscription(myLanguage: SourceLanguage, config?: TranscriptionConfig): Promise<void>;
    /**
     * Stop transcription
     *
     * Stop the ongoing AI transcription service. After stopping, the transcriber will no longer recognize speech or provide transcription results.
     */
    stopTranscription(): Promise<void>;
    /**
     * Start interpretation
     *
     * Start the AI interpretation service with the specified language and configuration.
     * Once started, the interpreter will provide real-time voice interpretation in the room.
     *
     * @param myLanguage The source language for interpretation.
     * @param config Interpretation configuration, including voice type.
     */
    startInterpretation(myLanguage: SourceLanguage, config?: InterpretationConfig): Promise<void>;
    /**
     * Update interpretation configuration
     *
     * Update the configuration of the ongoing interpretation service.
     *
     * @param myLanguage The new source language for interpretation.
     * @param config New interpretation configuration.
     */
    updateInterpretation(myLanguage: SourceLanguage, config?: InterpretationConfig): Promise<void>;
    /**
     * Stop interpretation
     *
     * Stop the ongoing AI interpretation service.
     */
    stopInterpretation(): Promise<void>;
    /**
     * Set interpretation volume
     *
     * Set the volume level for the interpretation audio output.
     *
     * @param volume Volume level.
     */
    setInterpretationVolume(volume: number): Promise<void>;
    /**
     * Start real-time transcription
     *
     * Start the AI real-time transcription service with the specified configuration.
     * Once started, the transcriber will recognize speech in the room and provide real-time transcription and translation results through the state publisher.
     *
     * @param config Transcription configuration, including source language and translation languages.
     * @deprecated Use startTranscription instead
     */
    startRealtimeTranscriber(config: TranscriberConfig): Promise<void>;
    /**
     * Update transcription configuration
     *
     * Update the configuration of the ongoing real-time transcription service.
     * This can be used to change the source language or modify the translation language list without stopping and restarting the transcription.
     *
     * @param config New transcription configuration.
     * @deprecated Use updateTranscription instead
     */
    updateRealtimeTranscriber(config: TranscriberConfig): Promise<void>;
    /**
     * Stop real-time transcription
     *
     * Stop the ongoing AI real-time transcription service. After stopping, the transcriber will no longer recognize speech or provide transcription results.
     * @deprecated Use stopTranscription instead
     */
    stopRealtimeTranscriber(): Promise<void>;
}

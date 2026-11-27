/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   MusicStore @ AtomicXCore
 * Function: BGM playback related interfaces, managing music playback control, state synchronization, and playback event listening in live rooms/voice chat rooms.

 */
/**
 * Music playback status.
 */
export declare enum MusicPlayStatus {
    /**
     * Idle, not playing.
     */
    IDLE = 0,
    /**
     * Playing.
     */
    PLAYING = 1,
    /**
     * Paused.
     */
    PAUSED = 2,
    /**
     * Loading (e.g. buffering network resource).
     */
    LOADING = 3
}
/**
 * Music playback state, managing the playback data state of the current room.
 *
 * Contains all state information about the current music playback session, supports real-time updates.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | s | w | i | f | t |
 * | k | o | t | l | i | n |
 *
 * > **Tip**: Subscribe to {ref} to receive real-time updates of playback data.
 */
@Observed
export declare class MusicState {
    /**
     * Currently playing music URL. nil/null means no music is playing.
     */
    playURL: string | undefined;
    /**
     * Current playback status.
     */
    playStatus: MusicPlayStatus;
    /**
     * Current playback progress (unit: milliseconds).
     */
    playProgress: number;
    /**
     * Total duration of current music (unit: milliseconds). 0 means unknown.
     */
    totalDuration: number;
    /**
     * BGM volume, range 0 - 100, default 60.
     */
    musicVolume: number;
}
/**
 * Music playback parameters.
 *
 * Describes the music resource and playback behavior used by ``MusicStore/startPlay(param:completion:)``.
 * The SDK supports playing multiple tracks simultaneously, so each track is identified by a unique
 * ``id`` used to control start/stop/volume and so on.
 */
export declare class AudioMusicParam {
    /**
     * Music ID. Since the SDK allows playing multiple tracks at the same time, this ID is used to
     * mark a track for start/stop/volume control, etc. When 0, an ID will be generated internally
     * based on ``path``.
     */
    id: number;
    /**
     * Full path or URL of the audio file. Supported formats: MP3, AAC, M4A, WAV.
     */
    path: string;
    /**
     * Number of times to loop the track. 0 means play once without looping.
     */
    loopCount: number;
}
export declare class MusicListener {
    onPlayCompleted?: (playURL: string) => void;
    onPlayError?: (playURL: string, code: number) => void;
}
/**
 * BGM playback related interfaces, managing music playback control, state synchronization, and playback event listening in live rooms/voice chat rooms.
 *
 * `MusicStore` BGM playback management class for handling music playback related business logic in live rooms/voice chat rooms.
 * `MusicStore` provides a complete set of music playback management APIs, including starting/pausing/resuming/stopping playback and volume control.
 * Through this class, BGM playback functionality can be implemented in live rooms.
 *
 * ### Key Features
 *
 * - **Playback Control**: Support starting, pausing, resuming, stopping, and seeking BGM playback.
 * - **Volume Control**: Adjustable BGM volume (0-100).
 * - **Pitch Adjustment**: Support pitch shifting (-12 ~ 12).
 * - **State Management**: Real-time playback state updates via reactive state publisher.
 * - **Event Listening**: Listen to playback completion and error events.
 *
 * > **Important**: Use the {ref} factory method to create a `MusicStore` instance, passing a valid live room ID.
 *
 * > **Tip**: Playback state updates are delivered through the {ref} publisher. Subscribe to it to receive real-time updates of playback data in the room.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Playback Control
 *
 * ### Playback Parameters
 *
 */
export declare abstract class MusicStore {
    protected state: MusicState;
    get musicState(): MusicState;
    abstract addMusicListener(listener: MusicListener): void;
    abstract removeMusicListener(listener: MusicListener): void;
    static create(liveID: string): MusicStore;
    /**
     * Start playing music.
     *
     * Starts playing the music described by `param`. If a network URL is provided in ``AudioMusicParam/path``,
     * the SDK will handle downloading internally.
     * The playback status will transition to LOADING first, then to PLAYING when playback actually starts.
     *
     * **Error Codes**: On failure, the completion callback will return TRTC SDK error codes. See the error code table in `onPlayError` for details.
     *
     * @param param Music playback parameters. See ``AudioMusicParam``.
     */
    abstract startPlay(param: AudioMusicParam): Promise<void>;
    /**
     * Pause music playback.
     *
     * Pauses the currently playing music. The playback status will change to PAUSED.
     * Call resumePlay to resume playback from the paused position.
     */
    abstract pausePlay(): void;
    /**
     * Resume music playback.
     *
     * Resumes playback from the paused position. The playback status will change to PLAYING.
     */
    abstract resumePlay(): void;
    /**
     * Stop music playback.
     *
     * Stops the current music playback completely. The playback status will change to IDLE.
     * Unlike pause, stop will reset the playback position.
     */
    abstract stopPlay(): void;
    /**
     * Seek to specified playback position.
     *
     * Jumps to the specified time position in the currently playing music.
     *
     * @param ms Target playback position in milliseconds.
     */
    abstract seek(ms: number): void;
    /**
     * Set BGM volume.
     *
     * Sets both the local playback volume and the remote publishing volume simultaneously.
     *
     * @param volume BGM volume, range 0 - 100.
     */
    abstract setMusicVolume(volume: number): void;
    /**
     * Set pitch adjustment.
     *
     * Adjusts the pitch of the currently playing music.
     *
     * @param pitch Pitch adjustment value, range -12 ~ 12. Positive values raise the pitch, negative values lower it.
     */
    abstract setPitch(pitch: number): void;
}

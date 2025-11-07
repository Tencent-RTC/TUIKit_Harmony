import { ThemeState, Toast ,IMErrorCode } from '../../basecomponent/Index';
import { MessageBody, MessageInfo, MessageInputStore, MessageType, ErrorInfo } from '@tencentcloud/atomicxcore';
import { MessageInputMoreDialog, MenuItem } from './MessageInputMoreDialog';
import { EmojiDataManager, EmojiItem, EmojiPicker } from '../../emojipicker/Index';
import { AudioRecorder } from '../../audiorecorder/Index';
import { AudioRecorderView } from '../Index';
import { FilePicker } from '../../filepicker/Index';
import { VideoRecorder, RecordMode, VideoRecorderErrorCode, RecordListener } from '../../videorecorder/Index';
import { AlbumPicker, AlbumPickerResult, PickMode } from '../../albumpicker/Index';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { dataSharePredicates } from '@kit.ArkData';
import image from '@ohos.multimedia.image';
import { MessageInputConfigProtocol, ChatMessageInputConfig } from '../config/MessageInputConfig';

@Component
export struct MessageInput {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  // File size limits in bytes
  private static readonly IMAGE_AUDIO_MAX_SIZE = 28 * 1024 * 1024; // 28MB
  private static readonly VIDEO_FILE_MAX_SIZE = 100 * 1024 * 1024; // 100MB
  conversationID: string = '';
  config?: MessageInputConfigProtocol = undefined;
  private effectiveConfig: MessageInputConfigProtocol = new ChatMessageInputConfig();
  dialogController?: CustomDialogController = undefined;
  private richEditorController: RichEditorController = new RichEditorController();
  @State private inputState: MessageInputStore | null = null;
  @State private showEmojiPicker: boolean = false;
  private context = getContext(this) as common.UIAbilityContext;
  @State private inputFocused: boolean = false;
  private hiddenButtonId: string = 'hiddenFocusButton';
  @State private isVoiceRecording: boolean = false;
  @State private recordingDuration: number = 0;
  @State private showKeyboardPlaceholder: boolean = false;
  @State private shouldCancelRecording: boolean = false;
  @State private dragOffset: number = 0;
  private readonly cancelThreshold: number = -50; // Upward drag threshold for cancel
  private longPressTimer?: number;
  private initialTouchY: number = 0;

  aboutToAppear() {
    if (this.conversationID) {
      this.inputState = MessageInputStore.create(this.conversationID);
    } else {
      console.error('[MessageInputBar] No conversationID provided, input state will not be created');
    }

    // Initialize style
    if (this.config) {
      this.effectiveConfig = this.config;
    }

    AudioRecorder.getInstance().setContext(this.context);
    
    // Initialize dialog controller with dynamic menu items
    this.initializeDialogController();
  }

  // Initialize dialog controller with menu items based on style
  private initializeDialogController(): void {
    const menuItems: MenuItem[] = [];

    // Add default menu items based on style
      menuItems.push({
        id: 'image',
        text: $r('app.string.menu_image'),
        icon: $rawfile('messageinput/image_icon.svg'),
        action: () => {
          this.selectImage();
        }
      });

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'photo',
        text: $r('app.string.menu_photo'),
        icon: $rawfile('messageinput/camera_action_icon.svg'),
        action: () => {
          this.takePhoto();
        }
      });
    }

    if (this.effectiveConfig.isShowPhotoTaker) {
      menuItems.push({
        id: 'video',
        text: $r('app.string.menu_video'),
        icon: $rawfile('messageinput/video_icon.svg'),
        action: () => {
          this.recordVideo();
        }
      });
    }

      menuItems.push({
        id: 'file',
        text: $r('app.string.menu_file'),
        icon: $rawfile('messageinput/document_icon.svg'),
        action: () => {
          this.selectFile();
        }
      });

    // Create dialog controller with menu items
    this.dialogController = new CustomDialogController({
      builder: MessageInputMoreDialog({
        menuItems: menuItems,
        onCancel: () => {
          console.log('[MessageInput] More dialog cancelled');
        }
      }),
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -16 },
      customStyle: true,
      autoCancel: true
    });
  }


  build() {
    Column() {

      if (this.isVoiceRecording) {
        // Voice recording overlay
        AudioRecorderView({
          recordingDuration: this.recordingDuration,
          shouldCancelRecording: this.shouldCancelRecording,
          primaryColor: this.themeState.colors.textColorLink || '#4A90E2',
          onCancel: () => {
            this.cancelVoiceRecording();
          },
          onSend: () => {
            this.finishVoiceRecording();
          },
          onTimeLimitReached: () => {
            this.finishVoiceRecording();
          }
        })
      } else {

        Row() {

          // Show more actions button if enabled
          if (this.effectiveConfig.isShowMore) {
            Button() {
              Image($rawfile('messageinput/plus_icon.svg'))
                .width(20)
                .height(20)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.themeState.getCurrentTheme().bgColorOperate)
            .borderRadius(18)
            .onClick(() => {

              this.showEmojiPicker = false;
              this.hideKeyboard();
              if (this.dialogController) {
                this.dialogController.open();
              }
            })
          }


          Stack() {

            Row() {

              RichEditor({
                controller: this.richEditorController
              })
                .backgroundColor(this.themeState.colors.bgColorInput)
                .borderRadius(0)
                .layoutWeight(1)
                .constraintSize({
                  minHeight: 36,
                  maxHeight: 120
                })
                .padding({
                  left: 0,
                  right: 8,
                  top: 8,
                  bottom: 8
                })
                .focusable(true)
                .defaultFocus(this.inputFocused && !this.showEmojiPicker)
                .enterKeyType(EnterKeyType.Send)
                .placeholder($r('app.string.input_message_placeholder'), {
                  fontColor: this.themeState.colors.textColorTertiary,
                  font: {
                    size: 14,
                    weight: FontWeight.Normal,
                    family: "HarmonyOS Sans",
                    style: FontStyle.Normal
                  }
                })
                .onReady(() => {

                })
                .onFocus(() => {
                  console.log('[MessageInput] RichEditor onFocus triggered');
                  this.inputFocused = true;

                  if (this.showEmojiPicker) {
                    this.showEmojiPicker = false;
                  }

                  // Delay showing keyboard placeholder to ensure focus is stable
                  setTimeout(() => {
                    if (this.inputFocused) {
                      this.showKeyboardPlaceholder = true;
                      console.log('[MessageInput] Keyboard placeholder shown');
                    }
                  }, 100);
                })
                .onBlur(() => {
                  console.log('[MessageInput] RichEditor onBlur triggered');
                  this.inputFocused = false;
                  this.showKeyboardPlaceholder = false;
                  console.log('[MessageInput] Keyboard placeholder hidden');
                })
                .onClick(() => {
                  console.log('[MessageInput] RichEditor onClick triggered');

                  if (this.showEmojiPicker) {
                    this.showEmojiPicker = false;
                  }

                  this.inputFocused = true;
                })
                .onSubmit(() => {


                  this.sendTextMessage();
                })
                .onIMEInputComplete((value: RichEditorTextSpanResult) => {

                  if (value.value && value.value.length > 0) {

                    const selection = this.richEditorController.getSelection();
                    const start = selection.selection[0];
                    const end = selection.selection[1];


                    this.richEditorController.updateSpanStyle({
                      start: start - value.value.length,
                      end: start,
                      textStyle: {
                        fontColor: this.themeState.colors.textColorPrimary
                      }
                    });
                  }
                })


              // Show emoji button if enabled
                Image(this.showEmojiPicker ? $rawfile('messageinput/keyboard_icon.svg') :
                $rawfile('messageinput/emoji_icon.svg'))
                  .width(19)
                  .height(19)
                  .onClick(() => {
                    if (this.showEmojiPicker) {
                      // Switch from emoji picker to keyboard
                      this.showEmojiPicker = false;
                      this.inputFocused = true;
                      // Don't set showKeyboardPlaceholder here, let onFocus handle it
                      setTimeout(() => {
                        try {
                          this.richEditorController.getCaretOffset();
                        } catch (error) {
                          console.warn('[MessageInput] Failed to get caret offset:', error);
                        }
                      }, 50);
                    } else {
                      // Switch from keyboard to emoji picker
                      this.hideKeyboard();
                      this.showEmojiPicker = true;
                    }
                  })
            }
            .width('100%')
            .constraintSize({
              minHeight: 36,
              maxHeight: 120
            })
            .backgroundColor(this.themeState.colors.bgColorInput)
            .borderRadius(18)
            .padding({ left: 16, right: 16 })
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
          }
          .layoutWeight(1)
          .constraintSize({
            minHeight: 36,
            maxHeight: 120
          })
          .backgroundColor(this.themeState.colors.bgColorInput)
          .borderRadius(18)
          .padding({ left: 16, right: 16 })


          // Show voice input button if enabled
          if (this.effectiveConfig.isShowAudioRecorder) {
            Button() {
              Image($rawfile('messageinput/microphone_icon.svg'))
                .width(24)
                .height(24)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.isVoiceRecording ? '#4A90E2' : this.themeState.colors.bgColorOperate)
            .borderRadius(18)
            .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              console.log('[MessageInput] Touch down - start long press timer');
              this.initialTouchY = event.touches[0].y;
              this.startLongPressTimer();
            } else if (event.type === TouchType.Move) {
              if (this.isVoiceRecording) {
                // Calculate drag offset from initial touch position
                this.dragOffset = event.touches[0].y - this.initialTouchY;
                this.shouldCancelRecording = this.dragOffset < this.cancelThreshold;
                console.log(`[MessageInput] Touch move - drag offset: ${this.dragOffset}, shouldCancel: ${this.shouldCancelRecording}`);
              }
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              console.log('[MessageInput] Touch up/cancel');
              this.cancelLongPressTimer();
              if (this.isVoiceRecording) {
                if (this.shouldCancelRecording) {
                  this.cancelVoiceRecording();
                } else {
                  this.finishVoiceRecording();
                }
              }
            }
          })
            .gesture(
              // Pan gesture for drag detection during recording
              PanGesture({ fingers: 1, direction: PanDirection.Vertical, distance: 1 })
                .onActionUpdate((event: GestureEvent) => {
                  if (this.isVoiceRecording) {
                    this.dragOffset = event.offsetY;
                    this.shouldCancelRecording = this.dragOffset < this.cancelThreshold;
                    console.log(`[MessageInput] Pan update - drag offset: ${this.dragOffset}, shouldCancel: ${this.shouldCancelRecording}`);
                  }
                })
            )
          }

          // Show camera button if image input is enabled
          if (this.effectiveConfig.isShowPhotoTaker) {
            Button() {
              Image($rawfile('messageinput/camera_icon.svg'))
                .width(24)
                .height(24)
            }
            .width(36)
            .height(36)
            .backgroundColor(this.themeState.colors.bgColorOperate)
            .borderRadius(18)
            .onClick(() => {

              this.showEmojiPicker = false;
              this.hideKeyboard();
              this.takePhoto();
            })
          }
        }
        .width('100%')
        .constraintSize({
          minHeight: 50,
          maxHeight: 120
        })
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }


      Button()
        .width(0)
        .height(0)
        .opacity(0)
        .focusable(true)
        .id(this.hiddenButtonId)


      if (this.showEmojiPicker) {
        EmojiPicker({
          onEmojiClick: (emoji: EmojiItem) => {
            this.handleEmojiSelected(emoji);
          },
          onDeleteClick: () => {
            this.handleDeleteLastCharacter();
          },
          onSendClick: () => {
            this.sendTextMessage();
            // this.showEmojiPicker = false;
          }
        })
          .transition({
            type: TransitionType.Insert,
            opacity: 1,
            translate: { y: 0 }
          })
          .transition({
            type: TransitionType.Delete,
            opacity: 0,
            translate: { y: 280 }
          })
      }

      // Keyboard placeholder to push input bar up
      if (this.showKeyboardPlaceholder && !this.showEmojiPicker) {
        Column()
          .width('100%')
          .height(280) // Same height as emoji picker
          .backgroundColor('transparent')
          .transition({
            type: TransitionType.Insert,
            opacity: 1,
            translate: { y: 0 }
          })
          .transition({
            type: TransitionType.Delete,
            opacity: 0,
            translate: { y: 280 }
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
  }

  private async sendTextMessage() {
    const messageText = await this.getMessageText();
    if (!messageText.trim() || !this.inputState) {
      return;
    }


    this.clearEditor();

    try {
      const messageBody = new MessageBody();
      messageBody.text = messageText.trim();

      const message = new MessageInfo();
      message.messageType = MessageType.Text;
      message.messageBody = messageBody;
      message.isSelf = true;
      message.timestamp = new Date().getTime();
      message.ID = '';

      this.inputState.sendMessage(message)
        .then(() => {
            //send success
        })
        .catch((error: ErrorInfo) => {
          const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
          Toast.error(localizedMessage, this.getUIContext());
        });
    } catch (error) {
    }
  }

  private async selectImage(): Promise<void> {
    try {
      const results: AlbumPickerResult[] = await AlbumPicker.pickMedia();
      if (results.length > 0) {
        const result = results[0]; 
        if (result.filePath) {
          if (result.type === PickMode.IMAGE) {
            this.handleSelectedMedia(result.filePath, MessageType.Image);
          } else if (result.type === PickMode.VIDEO) {
            this.handleSelectedMedia(result.filePath, MessageType.Video);
          }
        }
      } else {
      }
    } catch (error) {
    }
  }

  private async takePhoto(): Promise<void> {
    try {
      const videoRecorder = VideoRecorder.getInstance();
      
      await videoRecorder.takePhoto(
        { defaultFrontCamera: false },
        {
          onPhotoCaptured: (filePath: string) => {
            console.log(`[MessageInput] Photo captured successfully: ${filePath}`);
            this.handleSelectedMedia(filePath, MessageType.Image);
          },
          onError: (errorCode: VideoRecorderErrorCode) => {
            console.error(`[MessageInput] Photo capture failed: ${errorCode}`);
          }
        } as RecordListener,
        this.context
      );
    } catch (error) {
      console.error('[MessageInput] Photo capture error:', error);
    }
  }

  private async recordVideo(): Promise<void> {
    try {
      const videoRecorder = VideoRecorder.getInstance();
      
      await videoRecorder.takeVideo(
        { recordMode: RecordMode.VIDEO_ONLY },
        {
          onVideoCaptured: (filePath: string, duration: number) => {
            console.log(`[MessageInput] Video recorded successfully: ${filePath}, duration: ${duration}s`);
            this.handleSelectedMedia(filePath, MessageType.Video);
          },
          onError: (errorCode: VideoRecorderErrorCode) => {
            console.error(`[MessageInput] Video recording failed: ${errorCode}`);
          }
        } as RecordListener,
        this.context
      );
    } catch (error) {
      console.error('[MessageInput] Video recording error:', error);
    }
  }

  private async handleSelectedMedia(mediaPath: string, messageType: MessageType) {
    if (!this.inputState) {

      return;
    }
    const user_file_uri = mediaPath;
    // Use temporary cache directory instead of ChatUtil.getMediaHomePath
    const tempDir = getContext().getApplicationContext().cacheDir + "/media/";
    const fileName = user_file_uri.split("/").pop() || `temp_${Date.now()}`;
    const app_file_path = tempDir + fileName;

    // Ensure temp directory exists
    try {
      await fs.mkdir(tempDir, true);
    } catch (error) {
      // Directory might already exist, ignore error
    }

    let user_file = await fs.open(user_file_uri, fs.OpenMode.READ_ONLY);
    let app_file = await fs.open(app_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    await fs.copyFile(user_file.fd, app_file.fd, 0);
    await fs.close(user_file);
    await fs.close(app_file);

    try {
      
      const messageBody = new MessageBody();

      if (messageType === MessageType.Image) {
        messageBody.originalImagePath = app_file_path;
        
        try {
          const imageSourceApi = image.createImageSource(app_file_path);
          const imageInfo = await imageSourceApi.getImageInfo();
          messageBody.originalImageWidth = imageInfo.size.width;
          messageBody.originalImageHeight = imageInfo.size.height;
          console.log(`[MessageInput] Image dimensions: ${imageInfo.size.width}x${imageInfo.size.height}`);
        } catch (error) {
          console.error('[MessageInput] Failed to get image dimensions:', error);
          messageBody.originalImageWidth = 0;
          messageBody.originalImageHeight = 0;
        }
      } else if (messageType === MessageType.Video) {
        messageBody.videoPath = app_file_path;

        const videoFileName = app_file_path.split("/").pop()?.split(".")[0] || "video_cover";
        const thumbnail_file_path = tempDir + videoFileName + "_cover.jpg";

        try {
          let predicates = new dataSharePredicates.DataSharePredicates();
          predicates.equalTo("uri", user_file_uri);
          let fetchResult = await photoAccessHelper.getPhotoAccessHelper(getContext()).getAssets({
            fetchColumns: [photoAccessHelper.PhotoKeys.DURATION],
            predicates: predicates,
          });
          const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
          
          const videoDuration = asset.get(photoAccessHelper.PhotoKeys.DURATION) as number;
          messageBody.videoDuration = (videoDuration / 1000);
          console.log(`[MessageInput] Video duration: ${messageBody.videoDuration} seconds`);
          
          const thumbnail: image.PixelMap = await asset.getThumbnail();
          const thumbnailInfo = await thumbnail.getImageInfo();
          messageBody.videoSnapshotWidth =  thumbnailInfo.size.width;
          messageBody.videoSnapshotHeight = thumbnailInfo.size.height;
          console.log(`[MessageInput] Video thumbnail dimensions: ${thumbnailInfo.size.width}x${thumbnailInfo.size.height}`);
          
          const imagePackerApi = image.createImagePacker();
          const thumbnail_file = await fs.open(thumbnail_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
          await imagePackerApi.packToFile(thumbnail, thumbnail_file.fd, {
            format: "image/jpeg",
            quality: 100,
          });
          await fs.close(thumbnail_file);
          messageBody.videoSnapshotPath = thumbnail_file_path;
        } catch (error) {
          console.error('[MessageInput] Failed to get video info or generate thumbnail:', error);
          messageBody.videoDuration = 1;
          messageBody.videoSnapshotPath = '';
        }
      }


      const message = new MessageInfo();
      message.messageType = messageType;
      message.messageBody = messageBody;
      message.isSelf = true;
      message.timestamp = new Date().getTime();
      message.ID = '';

      // Send message
      if (this.inputState) {
        this.inputState.sendMessage(message)
          .then(() => {

          })
          .catch((error: ErrorInfo) => {
            const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
            Toast.error(localizedMessage, this.getUIContext());
          });
      }
    } catch (error) {

    }
  }

  private handleEmojiSelected(emoji: EmojiItem) {
    this.insertEmojiToEditor(emoji);
    this.inputFocused = false;
  }

  private handleDeleteLastCharacter() {
    try {
      const spans = this.richEditorController.getSpans({
        start: 0,
        end: -1
      });

      if (!spans || spans.length === 0) {
        return;
      }
      let totalLength = 0;
      spans.forEach((span) => {
        const textSpan = span as RichEditorTextSpanResult;
        if (textSpan.value !== undefined && textSpan.value !== null) {
          totalLength += textSpan.value.length;
        } else {
          totalLength += 1;
        }
      });
      if (totalLength > 0) {
        this.richEditorController.deleteSpans({
          start: totalLength - 1,
          end: totalLength
        });
      } else {
      }

    } catch (error) {
    }
  }

  private async getMessageText(): Promise<string> {
    try {
      const spans = await this.richEditorController.getSpans({
        start: 0,
        end: -1
      });

      let messageText = '';
      spans.forEach((span, index) => {
        const textSpan = span as RichEditorTextSpanResult;
        if (textSpan.value !== undefined && textSpan.value !== null) {
          messageText += textSpan.value;
          return;
        }
        const imageSpan = span as RichEditorImageSpanResult;
        if (imageSpan.valueResourceStr !== undefined || imageSpan.valuePixelMap !== undefined) {
          let imageResource: string | Resource | undefined = imageSpan.valueResourceStr;
          if (imageResource) {
            let resourceStr = '';
            if (typeof imageResource === 'string') {
              resourceStr = imageResource;
            } else {

              resourceStr = JSON.stringify(imageResource);
            }


            const emojiName = EmojiDataManager.getEmojiNameByResourceString(resourceStr);

            if (emojiName) {

              messageText += emojiName;
            } else {
              console.warn(`[MessageInputBar] No corresponding emoticon name found，Resource: ${resourceStr}`);
            }
          } else {
            console.warn(`[MessageInputBar] Resource attribute not found in image span`);
          }
        } else {
          console.warn(`[MessageInputBar] span of unknown type: ${JSON.stringify(span)}`);
        }
      });


      return messageText;

    } catch (error) {

      return '';
    }
  }

  private insertEmojiToEditor(emoji: EmojiItem) {
    try {
      const emojiResource = EmojiDataManager.getEmojiImageResource(emoji.imageFile);
      const selection = this.richEditorController.getSelection();
      const cursorPosition = selection.selection[1];
      this.richEditorController.addImageSpan(emojiResource, {
        imageStyle: {
          size: [20, 20],
          verticalAlign: ImageSpanAlignment.CENTER,
          objectFit: ImageFit.Contain
        },
        offset: cursorPosition
      });
    } catch (error) {
    }
  }

  private clearEditor() {
    try {
      this.richEditorController.deleteSpans();
    } catch (error) {
    }
  }

  private hideKeyboard() {
    this.inputFocused = false;
    this.showKeyboardPlaceholder = false;
    try {
      focusControl.requestFocus(this.hiddenButtonId);
    } catch (error) {
      console.warn('[MessageInputBar] hideKeyboard error:', error);
    }
  }

  // Start long press timer
  private startLongPressTimer(): void {
    this.longPressTimer = setTimeout(() => {
      console.log('[MessageInput] Long press timer triggered - start recording');
      this.startVoiceRecording();
    }, 300);
  }

  // Cancel long press timer
  private cancelLongPressTimer(): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = undefined;
    }
  }

  // Start voice recording with gesture control
  private startVoiceRecording(): void {
    this.showEmojiPicker = false;
    this.hideKeyboard();
    
    // Reset recording state
    this.shouldCancelRecording = false;
    this.dragOffset = 0;
    
    AudioRecorder.getInstance().startRecord(null, false, {
      onDurationUpdate: (duration: number) => {
        this.recordingDuration = duration;
      },
      onRecordingStart: () => {
        this.isVoiceRecording = true;
        console.log('[MessageInput] Voice recording started');
      },
      onRecordingStop: (filePath: string, duration: number) => {
        this.isVoiceRecording = false;
        this.sendVoiceMessage(duration, filePath);
        console.log('[MessageInput] Voice recording stopped');
      },
      onRecordingCancel: () => {
        this.isVoiceRecording = false;
        this.recordingDuration = 0;
        this.shouldCancelRecording = false;
        this.dragOffset = 0;
        console.log('[MessageInput] Voice recording cancelled');
      }
    });
  }

  // Finish voice recording (send message)
  private finishVoiceRecording(): void {
    if (this.isVoiceRecording) {
      AudioRecorder.getInstance().stopRecord();
    }
  }

  // Cancel voice recording
  private cancelVoiceRecording(): void {
    if (this.isVoiceRecording) {
      AudioRecorder.getInstance().cancelRecord();
    }
  }

  private async sendVoiceMessage(duration: number, voiceFilePath?: string) {
    if (!this.inputState) {
      return;
    }
    try {
      const filePath = voiceFilePath || '';
      if (!filePath) {
        return;
      }
      const messageBody = new MessageBody();
      messageBody.soundPath = filePath;
      messageBody.soundDuration = duration;
      const message = new MessageInfo();
      message.messageType = MessageType.Sound;
      message.messageBody = messageBody;
      message.isSelf = true;
      message.timestamp = new Date().getTime();
      message.ID = '';

      // Send message
      this.inputState.sendMessage(message)
        .then(() => {

        })
        .catch((error: ErrorInfo) => {
          const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
          Toast.error(localizedMessage, this.getUIContext());
        });

    } catch (error) {
    }
  }

  private async selectFile() {
    try {
      const results = await FilePicker.pickFiles({ maxCount: 1 });
      if (results.length > 0) {
        const filePath: string = results[0].filePath;
        this.handleSelectedFile(filePath);
      } else {
      }
    } catch (error) {
    }
  }

  private async handleSelectedFile(filePath: string) {
    if (!this.inputState) {
      return;
    }

    const user_file_uri = filePath;
    // Use temporary cache directory instead of ChatUtil.getMediaHomePath
    const tempDir = getContext().getApplicationContext().cacheDir + "/media/";
    const fileName = user_file_uri.split("/").pop() || `temp_file_${Date.now()}`;
    const app_file_path = tempDir + fileName;

    // Ensure temp directory exists
    try {
      await fs.mkdir(tempDir, true);
    } catch (error) {
      // Directory might already exist, ignore error
    }

    try {

      let user_file = await fs.open(user_file_uri, fs.OpenMode.READ_ONLY);
      let app_file = await fs.open(app_file_path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.copyFile(user_file.fd, app_file.fd, 0);
      await fs.close(user_file);
      await fs.close(app_file);


      const stat = await fs.stat(app_file_path);
      try {
        const fileSize = stat.size;

        // Check for empty file
        if (fileSize === 0) {
          Toast.error($r('app.string.empty_file_error'), this.getUIContext());
          return;
        }

        // Check file size limit (100MB)
        if (fileSize > MessageInput.VIDEO_FILE_MAX_SIZE) {
          Toast.error($r('app.string.file_size_too_large_error'), this.getUIContext());
          return;
        }
      } catch (error) {
        console.error('[MessageInput] Failed to check file size:', error);
        return;
      }

      const messageBody = new MessageBody();
      messageBody.filePath = app_file_path;
      messageBody.fileName = app_file_path.substring(app_file_path.lastIndexOf('/') + 1);
      messageBody.fileSize = stat.size;


      const message = new MessageInfo();
      message.messageType = MessageType.File;
      message.messageBody = messageBody;
      message.isSelf = true;
      message.timestamp = new Date().getTime();
      message.ID = '';

      // Send message
      this.inputState.sendMessage(message)
        .then(() => {
          //success
        })
        .catch((error: ErrorInfo) => {
          const localizedMessage = IMErrorCode.getErrorMessage(error.code ??-1,""+error.code +error.message);
          Toast.error(localizedMessage, this.getUIContext());
        });

    } catch (error) {

    }
  }
}

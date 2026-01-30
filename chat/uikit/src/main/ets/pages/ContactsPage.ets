import {
  ContactList,
  ContactInfo,
  AddContactDialog,
  SearchResultType,
  AppBuilderConfig
} from '@tencentcloud/atomicx'
import { ThemeState } from '@tencentcloud/atomicx'
import { ContactListStore } from '@tencentcloud/atomicxcore'


@Component
export struct ContactsPage {
  private static readonly HEADER_HEIGHT: number = 56;
  private static readonly LARGE_TITLE_HEIGHT: number = 52;
  private static readonly SEARCH_HEIGHT: number = 36;
  private static readonly SEARCH_BAR_HEIGHT: number = 36;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink contactListStore: ContactListStore;
  @State showAddMenu: boolean = false;
  private addContactDialogController: CustomDialogController | null = null;
  onContactClick?: (contact: ContactInfo) => void;
  onGroupClick?: (group: ContactInfo) => void;

  @Builder
  LargeTitleBuilder() {
    Row() {
      Text($r('app.string.contacts_title'))
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang HK')
        .layoutWeight(1)

      Row() {

        Image($r('app.media.new_chat_icon'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.showAddMenu = true;
          })
      }
    }
    .width('100%')
    .height(ContactsPage.LARGE_TITLE_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  

  @Builder
  AddMenuDialog() {
    Column() {

      Polygon({ width: 12, height: 6 })
        .points([[6, 0], [0, 6], [12, 6]])
        .fill(this.themeState.colors.bgColorOperate)// .stroke('#E5E5E5')
        .strokeWidth(1)
        .margin({ bottom: -1 })
        .alignSelf(ItemAlign.End)
        .margin({ right: 18 })


      Column() {

        Row() {
          Image($r('app.media.start_conversation_c2c'))
            .width(15)
            .height(17)
            .margin({ right: 12 })
            .fillColor(this.themeState.colors.textColorPrimary)

          Text($r('app.string.add_friend'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showAddMenu = false;
          this.handleAddFriend();
        })

        // Divider
        Divider()
          .color('#E5E5E5')
          .strokeWidth(0.5)
          .margin({ left: 52 })


        Row() {
          Image($r('app.media.start_conversation_group'))
            .width(19)
            .height(16)
            .margin({ right: 12 })
            .fillColor(this.themeState.colors.textColorPrimary)

          Text($r('app.string.add_group_chat'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showAddMenu = false;
          this.handleAddGroup();
        })
      }
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .borderRadius(12)
      .border({ width: 1, color: '#E5E5E5' })
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 2
      })
      .width(140)
    }
    .position({ x: '100%', y: ContactsPage.LARGE_TITLE_HEIGHT + 8 })
    .markAnchor({ x: 148, y: 0 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {

        this.LargeTitleBuilder()
        ContactList({
          contactListStore: this.contactListStore,
          onContactClick: (contact: ContactInfo) => {
            if (this.onContactClick) {
              this.onContactClick(contact);
            }
          },
          onGroupClick: (group: ContactInfo) => {
            if (this.onGroupClick) {
              this.onGroupClick(group);
            }
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .onClick(() => {

        if (this.showAddMenu) {
          this.showAddMenu = false;
        }
      })


      if (this.showAddMenu) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0)')
          .onClick(() => {
            this.showAddMenu = false;
          })
      }


      if (this.showAddMenu) {
        this.AddMenuDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  private handleAddFriend = () => {
    console.info('[ContactPage] handleAddFriend')
    if (this.addContactDialogController) {
      this.addContactDialogController.close();
      this.addContactDialogController = null;
    }
    this.addContactDialogController = new CustomDialogController({
      builder: AddContactDialog({
        onCancel: () => {

          this.addContactDialogController = null;
        },
        onSearchUser: (keyword: string) => {

        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Default,
      customStyle: true,
      cancel: () => {
        this.addContactDialogController = null;
      }
    });


    this.addContactDialogController.open();
  }
  private handleAddGroup = () => {
    console.info('[ContactPage] handleAddGroup')
    if (this.addContactDialogController) {
      this.addContactDialogController.close();
      this.addContactDialogController = null;
    }
    this.addContactDialogController = new CustomDialogController({
      builder: AddContactDialog({
        initialSearchType: SearchResultType.GROUP,
        onCancel: () => {
          this.addContactDialogController = null;
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Default,
      customStyle: true,
      cancel: () => {
        this.addContactDialogController = null;
      }
    });


    this.addContactDialogController.open();
  }
}
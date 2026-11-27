import { BuilderNode, FrameNode, NodeController, typeNode } from '@ohos.arkui.node'
import { UIContext } from '@ohos.arkui.UIContext'
import {
  AtomicLiveController,
  AtomicLiveView,
  AtomicLiveViewImpl,
  AtomicLiveViewType,
} from '@tencentcloud/atomicxcore'

@Builder
function videoContent(view: AtomicLiveView) {
  Stack() {
    AtomicLiveViewImpl({ view: view })
      .width('100%')
      .height('100%')
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.Black)
  .hitTestBehavior(HitTestMode.BLOCK_DESCENDANTS)
}

class FloatingVideoController extends NodeController {
  private readonly view: AtomicLiveView
  private builder?: BuilderNode<[AtomicLiveView]>
  private released: boolean = false

  constructor(view: AtomicLiveView) {
    super()
    this.view = view
  }

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.released) return null
    if (this.builder === undefined) {
      this.builder = new BuilderNode<[AtomicLiveView]>(uiContext)
      this.builder.build(wrapBuilder(videoContent), this.view)
    }
    return this.builder.getFrameNode()
  }

  release(): void {
    this.released = true
    this.builder?.dispose()
    this.builder = undefined
  }
}

export class FloatingContent {
  readonly controller: XComponentController = new XComponentController()
  readonly view: AtomicLiveView = new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.playView))
  readonly video: FloatingVideoController = new FloatingVideoController(this.view)
  readonly node: typeNode.XComponent
  private released: boolean = false

  constructor(uiContext: UIContext) {
    this.node = typeNode.createNode(uiContext, 'XComponent', {
      type: XComponentType.SURFACE,
      controller: this.controller,
    })
    this.node.attribute.width(160).height(90)
  }

  release(): void {
    if (this.released) return
    this.released = true
    this.video.release()
    this.node.dispose()
  }
}

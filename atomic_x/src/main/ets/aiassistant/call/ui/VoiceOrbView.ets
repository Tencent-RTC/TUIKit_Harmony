import { ThemeState } from '../../../basecomponent/Index';
import { AICallState } from '../AICallState';

export class VoiceOrbLevel {
  target: number = 0;

  set(level: number): void {
    this.target = Math.min(Math.max(level, 0), 1);
  }
}

interface Rgb {
  r: number;
  g: number;
  b: number;
}

@Component
export struct VoiceOrbView {
  private static readonly GLOW_RATIO: number = 0.22;
  private static readonly REST_SCALE: number = 0.85;
  private static readonly LEVEL_ATTACK: number = 0.38;
  private static readonly LEVEL_RELEASE: number = 0.10;
  private static readonly FRAME_INTERVAL_MS: number = 16;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @Prop @Watch('onStateChanged') state: AICallState = AICallState.IDLE;
  level: VoiceOrbLevel = new VoiceOrbLevel();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private phase: number = 0;
  private displayedLevel: number = 0;
  private animationStart: number = 0;
  private timer?: number;

  aboutToAppear(): void {
    this.restartAnimator();
  }

  aboutToDisappear(): void {
    this.stopAnimator();
  }

  onStateChanged(): void {
    if (this.state !== AICallState.SPEAKING) {
      this.level.target = 0;
      this.displayedLevel = 0;
    }
    this.restartAnimator();
    this.draw();
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.draw();
      })
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.canvasWidth = Number(newValue.width);
        this.canvasHeight = Number(newValue.height);
        this.draw();
      })
  }

  private restartAnimator(): void {
    this.stopAnimator();
    if (this.state === AICallState.IDLE) {
      return;
    }
    const duration = this.state === AICallState.LISTENING ? 2600 :
      (this.state === AICallState.THINKING ? 1400 : 2000);
    this.animationStart = Date.now();
    this.timer = setInterval(() => {
      this.phase = ((Date.now() - this.animationStart) % duration) / duration;
      if (this.state === AICallState.SPEAKING) {
        this.tickDisplayedLevel();
      }
      this.draw();
    }, VoiceOrbView.FRAME_INTERVAL_MS);
  }

  private stopAnimator(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
  }

  private tickDisplayedLevel(): void {
    const target = this.level.target;
    const alpha = target > this.displayedLevel ? VoiceOrbView.LEVEL_ATTACK : VoiceOrbView.LEVEL_RELEASE;
    this.displayedLevel += (target - this.displayedLevel) * alpha;
    if (Math.abs(this.displayedLevel - target) < 0.002) {
      this.displayedLevel = target;
    }
  }

  private draw(): void {
    const ctx = this.context;
    const width = this.canvasWidth;
    const height = this.canvasHeight;
    ctx.clearRect(0, 0, width, height);
    const cx = width / 2;
    const cy = height / 2;
    const maxRadius = Math.min(width, height) / 2;
    if (maxRadius <= 0) {
      return;
    }
    const baseRadius = maxRadius * (1 - VoiceOrbView.GLOW_RATIO);
    switch (this.state) {
      case AICallState.LISTENING: {
        const breath = VoiceOrbView.REST_SCALE + 0.07 * Math.sin(this.phase * 2 * Math.PI);
        this.drawGlowingOrb(cx, cy, maxRadius, baseRadius * breath);
        break;
      }
      case AICallState.SPEAKING:
        this.drawSpeaking(cx, cy, baseRadius);
        break;
      case AICallState.THINKING:
        this.drawThinking(cx, cy, maxRadius, baseRadius);
        break;
      default:
        this.drawGlowingOrb(cx, cy, maxRadius, baseRadius * VoiceOrbView.REST_SCALE);
        break;
    }
  }

  private drawGlowingOrb(cx: number, cy: number, maxRadius: number, radius: number): void {
    const ctx = this.context;
    const colors = this.themeState.colors;
    ctx.save();
    ctx.shadowBlur = maxRadius * VoiceOrbView.GLOW_RATIO;
    ctx.shadowColor = VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1);
    const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
    gradient.addColorStop(0, VoiceOrbView.toRgba(colors.buttonColorPrimaryHover, 1));
    gradient.addColorStop(0.6, VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1));
    gradient.addColorStop(1, VoiceOrbView.toRgba(colors.buttonColorPrimaryActive, 1));
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private drawSpeaking(cx: number, cy: number, baseRadius: number): void {
    const ctx = this.context;
    const colors = this.themeState.colors;
    const breath = Math.sin(this.phase * 2 * Math.PI);
    const radius = baseRadius * (0.84 + 0.14 * this.displayedLevel + 0.025 * breath);
    const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
    gradient.addColorStop(0, VoiceOrbView.toRgba(colors.buttonColorPrimaryHover, 1));
    gradient.addColorStop(0.48, VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1));
    gradient.addColorStop(0.78, VoiceOrbView.toRgba(colors.buttonColorPrimaryActive, 1));
    gradient.addColorStop(1, VoiceOrbView.toRgba(colors.buttonColorPrimaryActive, 0));
    ctx.save();
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private drawThinking(cx: number, cy: number, maxRadius: number, baseRadius: number): void {
    const ctx = this.context;
    const colors = this.themeState.colors;
    const radius = baseRadius * 0.84;
    const gradient = ctx.createConicGradient(this.phase * Math.PI * 2, cx, cy);
    gradient.addColorStop(0, VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1));
    gradient.addColorStop(0.34, VoiceOrbView.toRgba(colors.buttonColorPrimaryActive, 1));
    gradient.addColorStop(0.67, VoiceOrbView.toRgba(colors.buttonColorPrimaryHover, 1));
    gradient.addColorStop(1, VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1));
    ctx.save();
    ctx.shadowBlur = maxRadius * 0.12;
    ctx.shadowColor = VoiceOrbView.toRgba(colors.buttonColorPrimaryDefault, 1);
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private static toRgba(color: string, alpha: number): string {
    const rgb = VoiceOrbView.parseColor(color);
    return `rgba(${rgb.r},${rgb.g},${rgb.b},${alpha})`;
  }

  private static parseColor(color: string): Rgb {
    let hex = color.startsWith('#') ? color.substring(1) : color;
    if (hex.length === 8) {
      hex = hex.substring(2);
    }
    if (hex.length !== 6) {
      return { r: 0, g: 108, b: 255 };
    }
    const value = Number.parseInt(hex, 16);
    if (Number.isNaN(value)) {
      return { r: 0, g: 108, b: 255 };
    }
    return { r: (value >> 16) & 0xff, g: (value >> 8) & 0xff, b: value & 0xff };
  }
}

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import avplayerClass from '../services/avplayermanager';
import router from '@ohos.router'
import { DeeplinkHandler } from '../services/deeplinkHandler';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

    // Handle deeplink if present
    const uri = want.uri ?? (want.parameters?.uri as string | undefined);
    if (uri) {
      console.info('EntryAbility: Received deeplink:', uri);

      // Store URI for processing after context is set
      appStorage.setOrCreate('pendingDeeplink', uri);
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {

    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    // 传递上下文并初始化播放器（用于缓存/持久化目录与资源管理器）
    const rm = this.context.resourceManager;
    avplayerClass.setContext(this.context.cacheDir, this.context.filesDir, (path: string) => rm.getRawFileDescriptor(path));

    
    console.info('MusicNotification: 已配置通知管理器的跳转目标')
    avplayerClass.init().then(async ()=>{
      console.log('播放器初始化成功');

      // Process pending deeplink if present
      const pendingDeeplink = appStorage.get('pendingDeeplink') as string;
      if (pendingDeeplink) {
        console.info('EntryAbility: Processing pending deeplink:', pendingDeeplink);
        appStorage.setOrCreate('pendingDeeplink', ''); // Clear the pending deeplink

        const action = DeeplinkHandler.parseDeeplink(pendingDeeplink);
        if (action) {
          await DeeplinkHandler.processAction(action);
        }
      }
    })

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onNewWant(want: Want): void {
    // Check for deeplink URI
    const uri = want.uri ?? (want.parameters?.uri as string | undefined);
    if (uri) {
      console.info('EntryAbility: Received deeplink in onNewWant:', uri);

      const action = DeeplinkHandler.parseDeeplink(uri);
      if (action) {
        // Process async without blocking
        DeeplinkHandler.processAction(action).catch(error => {
          console.error('EntryAbility: Failed to process deeplink:', error);
        });
        return;
      }
    }

    // Default behavior: navigate to Playnow (for notification clicks)
    router.pushUrl({ url: 'pages/Playnow' }).catch(error => {
      console.error('EntryAbility: Failed to navigate to Playnow:', error);
    });
  }
}

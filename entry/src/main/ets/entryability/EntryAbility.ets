import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const TAG = 'EngineeringCamera';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 设置应用颜色模式
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onCreate');

    // 初始化应用基础服务
    this.initializeServices();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onDestroy');

    // 清理资源
    this.cleanup();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 主窗口创建，设置启动页面
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onWindowStageCreate');

    // 设置窗口属性
    this.configureWindow(windowStage);

    // 加载启动页面
    windowStage.loadContent('pages/common/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load splash page. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading splash page.');
    });
  }

  onWindowStageDestroy(): void {
    // 主窗口销毁，释放UI相关资源
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 应用切换到前台
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onForeground');
  }

  onBackground(): void {
    // 应用切换到后台
    hilog.info(DOMAIN, TAG, '%{public}s', 'EngineeringCamera Ability onBackground');
  }

  /**
   * 初���化应用服务
   */
  private initializeServices(): void {
    try {
      // 后续会在这里初始化各种服务
      // - 数据库服务
      // - 状态管理
      // - 权限检查
      hilog.info(DOMAIN, TAG, 'Initializing application services...');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize services: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 配置窗口属性
   */
  private configureWindow(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();

      // 设置窗口属性
      mainWindow.setWindowSystemBarEnable(['status', 'navigation']);

      hilog.info(DOMAIN, TAG, 'Window configuration completed');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to configure window: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    try {
      // 后续会在这里清理各种资源
      // - 数据库连接
      // - 状态管理
      // - 其他服务
      hilog.info(DOMAIN, TAG, 'Cleaning up resources...');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to cleanup resources: %{public}s', JSON.stringify(error));
    }
  }
}
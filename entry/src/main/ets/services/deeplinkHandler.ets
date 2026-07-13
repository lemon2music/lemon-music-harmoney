import avplayerClass from './avplayermanager';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

// Interface for deeplink actions
export interface DeeplinkAction {
  type: 'play_song' | 'unknown';
  songName?: string;
}

export class DeeplinkHandler {
  /**
   * Parse a deeplink URI into an action object
   * @param uri The deeplink URI to parse
   * @returns DeeplinkAction or null if invalid
   */
  static parseDeeplink(uri: string): DeeplinkAction | null {
    if (!uri || typeof uri !== 'string') {
      return null;
    }

    // Parse URI: mymusic://play?song=歌曲名称
    try {
      const urlPattern = /^mymusic:\/\/play\?(.*)$/;
      const match = uri.match(urlPattern);

      if (!match) {
        console.error('DeeplinkHandler: URI does not match expected pattern');
        return { type: 'unknown' };
      }

      const queryString = match[1];
      const params = new URLSearchParams(queryString);
      const songName = params.get('song');

      if (!songName || songName.trim().length === 0) {
        console.warn('DeeplinkHandler: Missing or empty song parameter');
        return { type: 'unknown' };
      }

      return {
        type: 'play_song',
        songName: decodeURIComponent(songName.trim())
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('DeeplinkHandler: Failed to parse URI:', errorMessage);
      return { type: 'unknown' };
    }
  }

  /**
   * Process a deeplink action
   * @param action The action to process
   */
  static async processAction(action: DeeplinkAction): Promise<void> {
    if (action.type === 'unknown') {
      await DeeplinkHandler.showErrorToast('Invalid deeplink format');
      await DeeplinkHandler.navigateToMain();
      return;
    }

    if (action.type === 'play_song' && action.songName) {
      try {
        // Initiate playback
        await avplayerClass.playSongByName(action.songName);

        // Navigate to Playnow page
        await DeeplinkHandler.navigateToPlayer();
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error('DeeplinkHandler: Failed to process play action:', errorMessage);
        await DeeplinkHandler.showErrorToast('Failed to play song');
        await DeeplinkHandler.navigateToMain();
      }
    }
  }

  /**
   * Navigate to the main page
   */
  private static async navigateToMain(): Promise<void> {
    try {
      await router.replaceUrl({
        url: 'pages/mainpage'
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('DeeplinkHandler: Failed to navigate to main page:', errorMessage);
    }
  }

  /**
   * Navigate to the player page
   */
  private static async navigateToPlayer(): Promise<void> {
    try {
      await router.pushUrl({
        url: 'pages/Playnow'
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('DeeplinkHandler: Failed to navigate to player page:', errorMessage);
      await DeeplinkHandler.showErrorToast('Failed to open player');
    }
  }

  /**
   * Show an error toast message
   * @param message The error message to display
   */
  private static async showErrorToast(message: string): Promise<void> {
    try {
      await promptAction.showToast({
        message: message,
        duration: 2000,
        bottom: 50
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('DeeplinkHandler: Failed to show toast:', errorMessage);
    }
  }
}

import { LLMConfig } from '@/types/llm_config';

const CONFIG_KEY = 'presenton_user_config';
const CONFIG_VERSION = '1.0';

export const ConfigStorage = {
  /**
   * 保存配置到 LocalStorage
   */
  save(config: LLMConfig): void {
    try {
      const configWithVersion = {
        version: CONFIG_VERSION,
        data: config,
        savedAt: new Date().toISOString()
      };
      localStorage.setItem(CONFIG_KEY, JSON.stringify(configWithVersion));
      console.log('✅ Configuration saved to browser LocalStorage');
    } catch (error) {
      console.error('❌ Failed to save configuration:', error);
      throw new Error('Failed to save configuration to browser storage');
    }
  },

  /**
   * 从 LocalStorage 加载配置
   */
  load(): LLMConfig | null {
    try {
      const saved = localStorage.getItem(CONFIG_KEY);
      if (!saved) {
        console.log('ℹ️ No saved configuration found');
        return null;
      }
      
      const parsed = JSON.parse(saved);
      
      // 检查版本兼容性
      if (parsed.version !== CONFIG_VERSION) {
        console.warn('⚠️ Configuration version mismatch, migrating...');
        // 可以在这里添加版本迁移逻辑
      }
      
      console.log('✅ Configuration loaded from LocalStorage');
      return parsed.data;
    } catch (error) {
      console.error('❌ Failed to load configuration:', error);
      return null;
    }
  },

  /**
   * 清除配置
   */
  clear(): void {
    try {
      localStorage.removeItem(CONFIG_KEY);
      console.log('🗑️ Configuration cleared from LocalStorage');
    } catch (error) {
      console.error('❌ Failed to clear configuration:', error);
    }
  },

  /**
   * 检查是否有保存的配置
   */
  hasConfig(): boolean {
    return localStorage.getItem(CONFIG_KEY) !== null;
  },

  /**
   * 导出配置为 JSON 字符串（用于备份）
   */
  export(): string {
    const config = this.load();
    if (!config) {
      throw new Error('No configuration to export');
    }
    return JSON.stringify(config, null, 2);
  },

  /**
   * 从 JSON 字符串导入配置（用于恢复）
   */
  import(configJson: string): void {
    try {
      const config = JSON.parse(configJson);
      this.save(config);
      console.log('✅ Configuration imported successfully');
    } catch (error) {
      console.error('❌ Failed to import configuration:', error);
      throw new Error('Invalid configuration format');
    }
  },

  /**
   * 获取配置的元信息
   */
  getMetadata(): { version: string; savedAt: string } | null {
    try {
      const saved = localStorage.getItem(CONFIG_KEY);
      if (!saved) return null;
      
      const parsed = JSON.parse(saved);
      return {
        version: parsed.version,
        savedAt: parsed.savedAt
      };
    } catch (error) {
      return null;
    }
  }
};

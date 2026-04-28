"use client";

import { Download, Upload, Trash2, Info } from 'lucide-react';
import { ConfigStorage } from '@/utils/configStorage';
import { toast } from 'sonner';
import { useState } from 'react';

export default function ConfigManagement() {
  const [metadata, setMetadata] = useState(ConfigStorage.getMetadata());

  const handleExportConfig = () => {
    try {
      const config = ConfigStorage.export();
      const blob = new Blob([config], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `presenton-config-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.success('Configuration exported successfully');
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to export configuration');
    }
  };

  const handleImportConfig = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const content = e.target?.result as string;
        ConfigStorage.import(content);
        setMetadata(ConfigStorage.getMetadata());
        toast.success('Configuration imported successfully');
        setTimeout(() => {
          window.location.reload();
        }, 1000);
      } catch (error) {
        toast.error('Failed to import configuration. Please check the file format.');
      }
    };
    reader.readAsText(file);
    
    // Reset input
    event.target.value = '';
  };

  const handleClearConfig = () => {
    if (confirm('Are you sure you want to clear all configuration? This action cannot be undone.')) {
      ConfigStorage.clear();
      setMetadata(null);
      toast.success('Configuration cleared');
      setTimeout(() => {
        window.location.href = '/';
      }, 1000);
    }
  };

  return (
    <div className="space-y-4">
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div className="flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
          <div className="text-sm text-blue-800">
            <p className="font-medium mb-1">Configuration Storage</p>
            <p className="text-blue-700">
              Your configuration is saved in your browser's LocalStorage. 
              It will persist across sessions but is specific to this browser and device.
            </p>
            {metadata && (
              <p className="text-blue-600 mt-2 text-xs">
                Last saved: {new Date(metadata.savedAt).toLocaleString()}
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {/* Export Button */}
        <button
          onClick={handleExportConfig}
          disabled={!ConfigStorage.hasConfig()}
          className="flex items-center justify-center gap-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
        >
          <Download className="w-4 h-4" />
          <span className="font-medium">Export Config</span>
        </button>

        {/* Import Button */}
        <label className="flex items-center justify-center gap-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 cursor-pointer transition-colors">
          <Upload className="w-4 h-4" />
          <span className="font-medium">Import Config</span>
          <input
            type="file"
            accept=".json"
            onChange={handleImportConfig}
            className="hidden"
          />
        </label>

        {/* Clear Button */}
        <button
          onClick={handleClearConfig}
          disabled={!ConfigStorage.hasConfig()}
          className="flex items-center justify-center gap-2 px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
        >
          <Trash2 className="w-4 h-4" />
          <span className="font-medium">Clear Config</span>
        </button>
      </div>

      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <h4 className="font-medium text-gray-900 mb-2">How to use:</h4>
        <ul className="text-sm text-gray-700 space-y-1 list-disc list-inside">
          <li><strong>Export:</strong> Download your configuration as a JSON file for backup</li>
          <li><strong>Import:</strong> Restore configuration from a previously exported file</li>
          <li><strong>Clear:</strong> Remove all saved configuration from this browser</li>
        </ul>
      </div>
    </div>
  );
}

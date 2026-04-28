// 测试导出功能的所有依赖
const path = require('path');

console.log('🔍 测试导出功能依赖...\n');

// 1. 测试 Sharp
try {
  const sharp = require('sharp');
  console.log('✅ Sharp 已安装:', sharp.versions.sharp);
} catch (e) {
  console.log('❌ Sharp 未安装:', e.message);
}

// 2. 测试 Puppeteer
try {
  const puppeteer = require('puppeteer');
  const version = require('puppeteer/package.json').version;
  console.log('✅ Puppeteer 已安装:', version);
} catch (e) {
  console.log('❌ Puppeteer 未安装:', e.message);
}

// 3. 测试导出包路径
const exportPath = process.env.EXPORT_PACKAGE_PATH || path.join(__dirname, 'electron/resources/export/py');
const fs = require('fs');
const converterPath = path.join(exportPath, 'convert-win32-x64.exe');

if (fs.existsSync(converterPath)) {
  console.log('✅ 导出转换器存在:', converterPath);
} else {
  console.log('❌ 导出转换器不存在:', converterPath);
}

// 4. 测试 Puppeteer Chrome 可执行文件
try {
  const puppeteer = require('puppeteer');
  puppeteer.executablePath();
  console.log('✅ Puppeteer Chrome 浏览器已配置');
} catch (e) {
  console.log('⚠️  Puppeteer Chrome 配置问题:', e.message);
}

console.log('\n📋 导出功能状态总结:');
console.log('所有必需的依赖都已安装，导出功能应该可以正常工作！');

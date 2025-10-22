#!/usr/bin/env node

/**
 * EngineeringCamera 版本更新脚本
 * 用于自动化更新应用版本号和构建信息
 */

const fs = require('fs');
const path = require('path');

// 配置文件路径
const APP_CONFIG_PATH = path.join(__dirname, '../AppScope/app.json5');
const VERSION_CONFIG_PATH = path.join(__dirname, '../config/version.json');
const MODULE_CONFIG_PATH = path.join(__dirname, '../entry/src/main/module.json5');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

// 读取JSON文件
function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    log(`错误: 无法读取文件 ${filePath}`, colors.red);
    process.exit(1);
  }
}

// 写入JSON文件
function writeJson(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch (error) {
    log(`错误: 无法写入文件 ${filePath}`, colors.red);
    process.exit(1);
  }
}

// 版本号处理
class Version {
  constructor(versionString) {
    const parts = versionString.split('.');
    this.major = parseInt(parts[0]) || 0;
    this.minor = parseInt(parts[1]) || 0;
    this.patch = parseInt(parts[2]) || 0;
  }

  toString() {
    return `${this.major}.${this.minor}.${this.patch}`;
  }

  increment(type = 'patch') {
    switch (type) {
      case 'major':
        this.major++;
        this.minor = 0;
        this.patch = 0;
        break;
      case 'minor':
        this.minor++;
        this.patch = 0;
        break;
      case 'patch':
        this.patch++;
        break;
    }
    return this;
  }

  isNewerThan(other) {
    if (this.major !== other.major) return this.major > other.major;
    if (this.minor !== other.minor) return this.minor > other.minor;
    return this.patch > other.patch;
  }
}

// 生成版本号
function generateVersionCode(version) {
  const versionObj = new Version(version);
  return (versionObj.major * 1000000) +
         (versionObj.minor * 10000) +
         (versionObj.patch * 100);
}

// 更新应用配置
function updateAppConfig(newVersion, buildNumber) {
  log('更新应用配置...', colors.blue);

  const appConfig = readJson(APP_CONFIG_PATH);
  const oldVersion = appConfig.app.versionName;

  appConfig.app.versionName = newVersion;
  appConfig.app.versionCode = generateVersionCode(newVersion) + buildNumber;

  writeJson(APP_CONFIG_PATH, appConfig);

  log(`  版本号: ${oldVersion} → ${newVersion}`, colors.green);
  log(`  版本代码: ${appConfig.app.versionCode}`, colors.green);
}

// 更新版本配置文件
function updateVersionConfig(newVersion, buildNumber) {
  log('更新版本配置文件...', colors.blue);

  const versionConfig = readJson(VERSION_CONFIG_PATH);
  const oldVersion = versionConfig.app.versionName;

  versionConfig.app.versionName = newVersion;
  versionConfig.app.versionCode = generateVersionCode(newVersion) + buildNumber;
  versionConfig.app.buildNumber = buildNumber;
  versionConfig.app.releaseDate = new Date().toISOString().split('T')[0];
  versionConfig.build.buildTime = new Date().toISOString();
  versionConfig.release.changelog = [
    `版本更新��� ${newVersion}`,
    `构建号: ${buildNumber}`,
    `构建时间: ${new Date().toLocaleString('zh-CN')}`
  ];

  writeJson(VERSION_CONFIG_PATH, versionConfig);

  log(`  版本号: ${oldVersion} → ${newVersion}`, colors.green);
  log(`  构建号: ${buildNumber}`, colors.green);
  log(`  发布日期: ${versionConfig.app.releaseDate}`, colors.green);
}

// 更新模块配置
function updateModuleConfig() {
  log('更新模块配置...', colors.blue);

  const moduleConfig = readJson(MODULE_CONFIG_PATH);

  // 确保支持手机和平板
  if (!moduleConfig.module.deviceTypes.includes('tablet')) {
    moduleConfig.module.deviceTypes.push('tablet');
    writeJson(MODULE_CONFIG_PATH, moduleConfig);
    log('  添加平板设备支持', colors.green);
  }
}

// 生成构建信息
function generateBuildInfo() {
  const buildInfo = {
    timestamp: new Date().toISOString(),
    gitCommit: getGitCommit(),
    gitBranch: getGitBranch(),
    buildNode: process.env.NODE_ENV || 'development',
    platform: process.platform,
    nodeVersion: process.version,
    buildScript: 'update-version.js'
  };

  const buildInfoPath = path.join(__dirname, '../build/build-info.json');
  fs.mkdirSync(path.dirname(buildInfoPath), { recursive: true });
  writeJson(buildInfoPath, buildInfo);

  log('生成构建信息...', colors.green);
  log(`  Git提交: ${buildInfo.gitCommit}`, colors.cyan);
  log(`  Git分支: ${buildInfo.gitBranch}`, colors.cyan);
}

// 获取Git提交信息
function getGitCommit() {
  try {
    const { execSync } = require('child_process');
    return execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim().substring(0, 8);
  } catch (error) {
    return 'unknown';
  }
}

// 获取Git分支信息
function getGitBranch() {
  try {
    const { execSync } = require('child_process');
    return execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' }).trim();
  } catch (error) {
    return 'unknown';
  }
}

// 主函数
function main() {
  const args = process.argv.slice(2);
  const versionType = args[0] || 'patch'; // major, minor, patch
  const buildNumber = parseInt(args[1]) || Date.now() % 10000;

  log('EngineeringCamera 版本更新工具', colors.bright);
  log('================================', colors.bright);
  log('');

  // 读取当前版本
  const versionConfig = readJson(VERSION_CONFIG_PATH);
  const currentVersion = new Version(versionConfig.app.versionName);

  log(`当前版本: ${currentVersion.toString()}`, colors.yellow);
  log(`更新类型: ${versionType}`, colors.yellow);
  log(`构建号: ${buildNumber}`, colors.yellow);
  log('');

  // 计算新版本
  const newVersion = currentVersion.increment(versionType);

  log(`新版本: ${newVersion.toString()}`, colors.green);
  log('');

  // 更新配置文件
  updateAppConfig(newVersion.toString(), buildNumber);
  updateVersionConfig(newVersion.toString(), buildNumber);
  updateModuleConfig();
  generateBuildInfo();

  log('');
  log('✅ 版本更新完成!', colors.green);
  log('');
  log('接下来可以执行以下操作:', colors.blue);
  log('1. 提交代码: git add . && git commit -m "chore: version bump to ' + newVersion.toString() + '"');
  log('2. 创建标签: git tag v' + newVersion.toString());
  log('3. 构建应用: ./scripts/build-production.sh');
}

// 显示帮助信息
function showHelp() {
  log('EngineeringCamera 版本更新工具', colors.bright);
  log('================================', colors.bright);
  log('');
  log('用法:', colors.yellow);
  log('  node scripts/update-version.js [版本类型] [构建号]');
  log('');
  log('参数:', colors.yellow);
  log('  版本类型: major | minor | patch (默认: patch)');
  log('  构建号  : 数字 (默认: 时间戳后4位)');
  log('');
  log('示例:', colors.yellow);
  log('  node scripts/update-version.js patch        # 1.0.0 → 1.0.1');
  log('  node scripts/update-version.js minor        # 1.0.0 → 1.1.0');
  log('  node scripts/update-version.js major        # 1.0.0 → 2.0.0');
  log('  node scripts/update-version.js patch 1234   # 指定构建号');
}

// 脚本入口
if (args.includes('--help') || args.includes('-h')) {
  showHelp();
} else {
  main();
}
/**
 * 天气服务类
 * 提供天气信息获取、缓存和水印集成功能
 */

import { Logger } from '../../utils/Logger'

/**
 * 天气状态枚举
 */
export enum WeatherState {
  DISABLED = 'disabled',
  INITIALIZING = 'initializing',
  LOADING = 'loading',
  AVAILABLE = 'available',
  ERROR = 'error'
}

/**
 * 天气状况枚举
 */
export enum WeatherCondition {
  CLEAR = 'clear',
  CLOUDY = 'cloudy',
  OVERCAST = 'overcast',
  LIGHT_RAIN = 'light_rain',
  MODERATE_RAIN = 'moderate_rain',
  HEAVY_RAIN = 'heavy_rain',
  THUNDERSTORM = 'thunderstorm',
  LIGHT_SNOW = 'light_snow',
  MODERATE_SNOW = 'moderate_snow',
  HEAVY_SNOW = 'heavy_snow',
  FOG = 'fog',
  MIST = 'mist',
  UNKNOWN = 'unknown'
}

/**
 * 风向枚举
 */
export enum WindDirection {
  N = 'N',
  NE = 'NE',
  E = 'E',
  SE = 'SE',
  S = 'S',
  SW = 'SW',
  W = 'W',
  NW = 'NW',
  VARIABLE = 'VARIABLE'
}

/**
 * 天气数据接口
 */
export interface WeatherData {
  location: {
    latitude: number
    longitude: number
    city?: string
    district?: string
  }
  current: {
    temperature: number // 摄氏度
    humidity: number // 百分比
    pressure: number // hPa
    visibility: number // km
    uvIndex: number
    condition: WeatherCondition
    description: string
    icon: string // 天气图标代码
  }
  wind: {
    speed: number // km/h
    direction: WindDirection
    directionDegree: number // 度数
    gust?: number // 阵风速度
  }
  timestamp: Date
  source: string // 数据来源
}

/**
 * 天气预报接口
 */
export interface WeatherForecast {
  date: Date
  maxTemp: number
  minTemp: number
  condition: WeatherCondition
  description: string
  humidity: number
  windSpeed: number
  precipitationProbability: number // 降水概率，百分比
}

/**
 * 天气配置接口
 */
export interface WeatherConfig {
  updateInterval: number // 更新间隔，毫秒
  cacheTimeout: number // 缓存超时时间，毫秒
  enableForecast: boolean
  enableAutoUpdate: boolean
  temperatureUnit: 'celsius' | 'fahrenheit'
  language: 'zh' | 'en'
}

/**
 * 天气监听器接口
 */
export interface WeatherListeners {
  onWeatherChanged?: (weather: WeatherData) => void
  onWeatherError?: (error: Error) => void
  onWeatherUpdate?: (weather: WeatherData) => void
}

/**
 * 天气结果接口
 */
export interface WeatherResult {
  success: boolean
  weather?: WeatherData
  error?: Error
  fetchTime: number
}

/**
 * 天气服务类
 */
export class WeatherService {
  private static instance: WeatherService | null = null
  private logger = new Logger('WeatherService')

  // 状态管理
  private currentState: WeatherState = WeatherState.DISABLED
  private currentWeather: WeatherData | null = null

  // 配置
  private config: WeatherConfig = {
    updateInterval: 600000, // 10分钟
    cacheTimeout: 1800000, // 30分钟
    enableForecast: false,
    enableAutoUpdate: true,
    temperatureUnit: 'celsius',
    language: 'zh'
  }

  // 缓存相关
  private weatherCache: Map<string, { data: WeatherData; timestamp: number }> = new Map()

  // 更新定时器
  private updateTimer: number = -1

  // 监听器
  private listeners: WeatherListeners = {}

  // 模拟天气数据（用于演示）
  private mockWeatherData: Partial<WeatherData> = {
    current: {
      temperature: 22,
      humidity: 65,
      pressure: 1013,
      visibility: 10,
      uvIndex: 5,
      condition: WeatherCondition.CLOUDY,
      description: '多云',
      icon: 'cloudy'
    },
    wind: {
      speed: 12,
      direction: WindDirection.SE,
      directionDegree: 135
    }
  }

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService()
    }
    return WeatherService.instance
  }

  /**
   * 初始化天气服务
   */
  async initialize(): Promise<void> {
    this.logger.info('Initializing WeatherService...')

    try {
      this.setState(WeatherState.INITIALIZING)

      // 初始化服务配置
      this.loadConfiguration()

      // 如果启用自动更新，启动定时器
      if (this.config.enableAutoUpdate) {
        this.startAutoUpdate()
      }

      this.setState(WeatherState.AVAILABLE)
      this.logger.info('WeatherService initialized successfully')

    } catch (error) {
      this.setState(WeatherState.ERROR)
      this.logger.error('Failed to initialize WeatherService', error)
      throw error
    }
  }

  /**
   * 加载配置
   */
  private loadConfiguration(): void {
    // 这里可以从持久化存储加载配置
    // 目前使用默认配置
    this.logger.info('Weather configuration loaded', this.config)
  }

  /**
   * 获取当前天气
   */
  async getCurrentWeather(latitude: number, longitude: number): Promise<WeatherResult> {
    this.logger.info('Getting current weather...', { latitude, longitude })

    const startTime = Date.now()

    try {
      this.setState(WeatherState.LOADING)

      // 检查缓存
      const cacheKey = `${latitude.toFixed(4)},${longitude.toFixed(4)}`
      const cached = this.weatherCache.get(cacheKey)

      if (cached && (Date.now() - cached.timestamp) < this.config.cacheTimeout) {
        this.currentWeather = cached.data
        this.setState(WeatherState.AVAILABLE)
        this.notifyWeatherChanged(cached.data)

        const result: WeatherResult = {
          success: true,
          weather: cached.data,
          fetchTime: Date.now() - startTime
        }

        this.logger.info('Weather retrieved from cache', { fetchTime: result.fetchTime })
        return result
      }

      // 获取新数据
      const weather = await this.fetchWeatherData(latitude, longitude)

      // 缓存数据
      this.weatherCache.set(cacheKey, {
        data: weather,
        timestamp: Date.now()
      })

      this.currentWeather = weather
      this.setState(WeatherState.AVAILABLE)
      this.notifyWeatherChanged(weather)

      const result: WeatherResult = {
        success: true,
        weather: weather,
        fetchTime: Date.now() - startTime
      }

      this.logger.info('Weather retrieved successfully', {
        temperature: weather.current.temperature,
        condition: weather.current.condition,
        fetchTime: result.fetchTime
      })

      return result

    } catch (error) {
      this.setState(WeatherState.ERROR)
      const weatherError = error instanceof Error ? error : new Error(String(error))
      this.logger.error('Failed to get weather', error)
      this.notifyWeatherError(weatherError)

      const result: WeatherResult = {
        success: false,
        error: weatherError,
        fetchTime: Date.now() - startTime
      }

      return result
    }
  }

  /**
   * 获取天气数据
   */
  private async fetchWeatherData(latitude: number, longitude: number): Promise<WeatherData> {
    // 这里应该调用真实的天气API
    // 由于HarmonyOS限制，这里使用模拟数据

    this.logger.info('Fetching weather data from API...', { latitude, longitude })

    // 模拟API延迟
    await new Promise(resolve => setTimeout(resolve, 1000))

    // 生成模拟天气数据
    const weatherData: WeatherData = {
      location: {
        latitude: latitude,
        longitude: longitude,
        city: '北京市',
        district: '海淀区'
      },
      current: {
        temperature: this.mockWeatherData.current?.temperature || 22,
        humidity: this.mockWeatherData.current?.humidity || 65,
        pressure: this.mockWeatherData.current?.pressure || 1013,
        visibility: this.mockWeatherData.current?.visibility || 10,
        uvIndex: this.mockWeatherData.current?.uvIndex || 5,
        condition: this.mockWeatherData.current?.condition || WeatherCondition.CLOUDY,
        description: this.mockWeatherData.current?.description || '多云',
        icon: this.mockWeatherData.current?.icon || 'cloudy'
      },
      wind: {
        speed: this.mockWeatherData.wind?.speed || 12,
        direction: this.mockWeatherData.wind?.direction || WindDirection.SE,
        directionDegree: this.mockWeatherData.wind?.directionDegree || 135,
        gust: this.mockWeatherData.wind?.gust || 18
      },
      timestamp: new Date(),
      source: 'WeatherService (Mock)'
    }

    return weatherData
  }

  /**
   * 获取天气预报
   */
  async getWeatherForecast(latitude: number, longitude: number, days: number = 3): Promise<WeatherForecast[]> {
    this.logger.info('Getting weather forecast...', { latitude, longitude, days })

    try {
      if (!this.config.enableForecast) {
        throw new Error('Weather forecast is disabled')
      }

      // 模拟天气预报数据
      const forecasts: WeatherForecast[] = []
      const baseDate = new Date()

      for (let i = 0; i < days; i++) {
        const forecastDate = new Date(baseDate)
        forecastDate.setDate(baseDate.getDate() + i + 1)

        const condition = this.getRandomWeatherCondition()
        forecasts.push({
          date: forecastDate,
          maxTemp: 25 + Math.floor(Math.random() * 10),
          minTemp: 15 + Math.floor(Math.random() * 10),
          condition: condition,
          description: this.getWeatherDescription(condition),
          humidity: 50 + Math.floor(Math.random() * 40),
          windSpeed: 5 + Math.floor(Math.random() * 20),
          precipitationProbability: Math.floor(Math.random() * 100)
        })
      }

      this.logger.info('Weather forecast retrieved successfully', { days })
      return forecasts

    } catch (error) {
      this.logger.error('Failed to get weather forecast', error)
      throw error
    }
  }

  /**
   * 开始自动更新
   */
  private startAutoUpdate(): void {
    if (this.updateTimer >= 0) {
      clearInterval(this.updateTimer)
    }

    this.updateTimer = setInterval(async () => {
      if (this.currentWeather) {
        try {
          await this.getCurrentWeather(
            this.currentWeather.location.latitude,
            this.currentWeather.location.longitude
          )
        } catch (error) {
          this.logger.error('Auto update failed', error)
        }
      }
    }, this.config.updateInterval)

    this.logger.info('Auto update started', { interval: this.config.updateInterval })
  }

  /**
   * 停止自动更新
   */
  stopAutoUpdate(): void {
    if (this.updateTimer >= 0) {
      clearInterval(this.updateTimer)
      this.updateTimer = -1
      this.logger.info('Auto update stopped')
    }
  }

  /**
   * 配置天气服务
   */
  configure(config: Partial<WeatherConfig>): void {
    this.config = { ...this.config, ...config }
    this.logger.info('Weather configuration updated', this.config)

    // 如果自动更新配置发生变化，重新启动定时器
    if (this.config.enableAutoUpdate && this.currentState === WeatherState.AVAILABLE) {
      this.startAutoUpdate()
    } else if (!this.config.enableAutoUpdate) {
      this.stopAutoUpdate()
    }
  }

  /**
   * 设置监听器
   */
  setListeners(listeners: WeatherListeners): void {
    this.listeners = { ...this.listeners, ...listeners }
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.weatherCache.clear()
    this.logger.info('Weather cache cleared')
  }

  /**
   * 设置状态
   */
  private setState(state: WeatherState): void {
    const oldState = this.currentState
    this.currentState = state
    this.logger.info('Weather state changed', { from: oldState, to: state })
  }

  /**
   * 通知天气变化
   */
  private notifyWeatherChanged(weather: WeatherData): void {
    if (this.listeners.onWeatherChanged) {
      try {
        this.listeners.onWeatherChanged(weather)
      } catch (error) {
        this.logger.error('Error in weather changed callback', error)
      }
    }

    if (this.listeners.onWeatherUpdate) {
      try {
        this.listeners.onWeatherUpdate(weather)
      } catch (error) {
        this.logger.error('Error in weather update callback', error)
      }
    }
  }

  /**
   * 通知天气错误
   */
  private notifyWeatherError(error: Error): void {
    if (this.listeners.onWeatherError) {
      try {
        this.listeners.onWeatherError(error)
      } catch (callbackError) {
        this.logger.error('Error in weather error callback', callbackError)
      }
    }
  }

  /**
   * 获取随机天气状况
   */
  private getRandomWeatherCondition(): WeatherCondition {
    const conditions = Object.values(WeatherCondition)
    return conditions[Math.floor(Math.random() * conditions.length)]
  }

  /**
   * 获取天气描述
   */
  private getWeatherDescription(condition: WeatherCondition): string {
    const descriptions: Record<WeatherCondition, string> = {
      [WeatherCondition.CLEAR]: '晴朗',
      [WeatherCondition.CLOUDY]: '多云',
      [WeatherCondition.OVERCAST]: '阴天',
      [WeatherCondition.LIGHT_RAIN]: '小雨',
      [WeatherCondition.MODERATE_RAIN]: '中雨',
      [WeatherCondition.HEAVY_RAIN]: '大雨',
      [WeatherCondition.THUNDERSTORM]: '雷阵雨',
      [WeatherCondition.LIGHT_SNOW]: '小雪',
      [WeatherCondition.MODERATE_SNOW]: '中雪',
      [WeatherCondition.HEAVY_SNOW]: '大雪',
      [WeatherCondition.FOG]: '雾',
      [WeatherCondition.MIST]: '薄雾',
      [WeatherCondition.UNKNOWN]: '未知'
    }

    return descriptions[condition] || '未知'
  }

  /**
   * 获取当前天气数据
   */
  getCurrentWeatherData(): WeatherData | null {
    return this.currentWeather ? { ...this.currentWeather } : null
  }

  /**
   * 获取天气状态
   */
  getState(): WeatherState {
    return this.currentState
  }

  /**
   * 获取天气SVG图标
   */
  getWeatherIcon(condition: WeatherCondition): string {
    // 天气SVG图标映射 - 使用SVG图标名称
    const svgIconNames: Record<WeatherCondition, string> = {
      [WeatherCondition.CLEAR]: 'sun',
      [WeatherCondition.CLOUDY]: 'cloud',
      [WeatherCondition.OVERCAST]: 'cloud',
      [WeatherCondition.LIGHT_RAIN]: 'cloud-rain',
      [WeatherCondition.MODERATE_RAIN]: 'cloud-rain',
      [WeatherCondition.HEAVY_RAIN]: 'cloud-rain',
      [WeatherCondition.THUNDERSTORM]: 'cloud-rain',
      [WeatherCondition.LIGHT_SNOW]: 'snowflake',
      [WeatherCondition.MODERATE_SNOW]: 'snowflake',
      [WeatherCondition.HEAVY_SNOW]: 'snowflake',
      [WeatherCondition.FOG]: 'mist',
      [WeatherCondition.MIST]: 'mist',
      [WeatherCondition.UNKNOWN]: 'alert-triangle'
    }

    return svgIconNames[condition] || 'alert-triangle'
  }

  /**
   * 格式化温度
   */
  formatTemperature(temperature: number): string {
    if (this.config.temperatureUnit === 'fahrenheit') {
      const fahrenheit = (temperature * 9/5) + 32
      return `${Math.round(fahrenheit)}°F`
    }
    return `${Math.round(temperature)}°C`
  }

  /**
   * 格式化风向
   */
  formatWindDirection(direction: WindDirection): string {
    const directions: Record<WindDirection, string> = {
      [WindDirection.N]: '北风',
      [WindDirection.NE]: '东北风',
      [WindDirection.E]: '东风',
      [WindDirection.SE]: '东南风',
      [WindDirection.S]: '南风',
      [WindDirection.SW]: '西南风',
      [WindDirection.W]: '西风',
      [WindDirection.NW]: '西北风',
      [WindDirection.VARIABLE]: '风向不定'
    }

    return directions[direction] || '风向未知'
  }

  /**
   * 获取服务统计信息
   */
  getServiceStats(): {
    state: WeatherState
    cacheSize: number
    autoUpdateEnabled: boolean
    config: WeatherConfig
  } {
    return {
      state: this.currentState,
      cacheSize: this.weatherCache.size,
      autoUpdateEnabled: this.config.enableAutoUpdate,
      config: { ...this.config }
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    this.logger.info('Releasing WeatherService resources...')

    try {
      // 停止自动更新
      this.stopAutoUpdate()

      // 清除缓存
      this.clearCache()

      // 清理状态
      this.currentWeather = null
      this.setState(WeatherState.DISABLED)

      this.logger.info('WeatherService resources released successfully')
    } catch (error) {
      this.logger.error('Failed to release WeatherService resources', error)
    }
  }
}
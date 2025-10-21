/**
 * 定位服务类
 * 提供GPS定位、海拔获取和方向传感器功能
 */

import { geoLocationManager } from '@kit.LocationServicesKit'
import { sensor } from '@kit.SensorServiceKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Logger } from '../../utils/Logger'
import { PermissionUtils, PermissionType } from '../../utils/PermissionUtils'

/**
 * 定位状态枚举
 */
export enum LocationState {
  DISABLED = 'disabled',
  INITIALIZING = 'initializing',
  SEARCHING = 'searching',
  LOCATED = 'located',
  ERROR = 'error'
}

/**
 * 定位精度枚举
 */
export enum LocationAccuracy {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  BEST = 'best'
}

/**
 * 位置数据接口
 */
export interface LocationData {
  latitude: number
  longitude: number
  altitude?: number
  accuracy?: number
  altitudeAccuracy?: number
  heading?: number
  speed?: number
  timestamp: Date
  address?: LocationAddress
}

/**
 * 地址信息接口
 */
export interface LocationAddress {
  country?: string
  province?: string
  city?: string
  district?: string
  street?: string
  streetNumber?: string
  postalCode?: string
  formattedAddress?: string
}

/**
 * 定位配置接口
 */
export interface LocationConfig {
  accuracy: LocationAccuracy
  timeout: number // 毫秒
  maximumAge: number // 缓存时间，毫秒
  enableHighAccuracy: boolean
  continuousUpdates: boolean
  updateInterval: number // 连续更新间隔，毫秒
}

/**
 * 方向数据接口
 */
export interface OrientationData {
  azimuth: number // 方位角，0-360度
  pitch: number // 俯仰角，-90到90度
  roll: number // 翻滚角，-180到180度
  timestamp: Date
  accuracy: number
}

/**
海拔数据接口
 */
export interface AltitudeData {
  altitude: number // 海拔高度，米
  accuracy: number // 精度，米
  pressure?: number // 气压，hPa
  timestamp: Date
}

/**
 * 定位结果接口
 */
export interface LocationResult {
  success: boolean
  location?: LocationData
  error?: Error
  acquireTime: number
}

/**
 * 定位监听器接口
 */
export interface LocationListeners {
  onLocationChanged?: (location: LocationData) => void
  onLocationError?: (error: Error) => void
  onOrientationChanged?: (orientation: OrientationData) => void
  onAltitudeChanged?: (altitude: AltitudeData) => void
}

/**
 * 定位服务类
 */
export class LocationService {
  private static instance: LocationService | null = null
  private logger = new Logger('LocationService')
  private permissionUtils: PermissionUtils

  // 状态管理
  private currentState: LocationState = LocationState.DISABLED
  private currentLocation: LocationData | null = null
  private currentOrientation: OrientationData | null = null
  private currentAltitude: AltitudeData | null = null

  // 配置
  private config: LocationConfig = {
    accuracy: LocationAccuracy.HIGH,
    timeout: 15000,
    maximumAge: 60000,
    enableHighAccuracy: true,
    continuousUpdates: false,
    updateInterval: 5000
  }

  // 定位相关
  private locationRequest: geoLocationManager.LocationRequest | null = null
  private isLocating: boolean = false
  private locationStartTime: number = 0

  // 传感器相关
  private orientationSensor: sensor.SensorId = sensor.SensorId.ORIENTATION
  private pressureSensor: sensor.SensorId = sensor.SensorId.PRESSURE
  private isOrientationSensorActive: boolean = false
  private isPressureSensorActive: boolean = false

  // 监听器
  private listeners: LocationListeners = {}

  private constructor() {
    this.permissionUtils = PermissionUtils.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService()
    }
    return LocationService.instance
  }

  /**
   * 初始化定位服务
   */
  async initialize(): Promise<void> {
    this.logger.info('Initializing LocationService...')

    try {
      // 检查定位权限
      await this.checkLocationPermissions()

      // 检查定位功能是否启用
      await this.checkLocationEnabled()

      // 创建定位请求
      await this.createLocationRequest()

      this.setState(LocationState.SEARCHING)
      this.logger.info('LocationService initialized successfully')
    } catch (error) {
      this.setState(LocationState.ERROR)
      this.logger.error('Failed to initialize LocationService', error)
      throw error
    }
  }

  /**
   * 检查定位权限
   */
  private async checkLocationPermissions(): Promise<void> {
    this.logger.info('Checking location permissions...')

    const locationPermissions = [
      PermissionType.APPROXIMATELY_LOCATION,
      // 可能还需要精确定位权限
    ]

    const results = await this.permissionUtils.checkPermissions(locationPermissions)
    const hasPermission = Object.values(results).some(result => result.granted)

    if (!hasPermission) {
      throw new Error('Location permission not granted')
    }

    this.logger.info('Location permissions check passed')
  }

  /**
   * 检查定位功能是否启用
   */
  private async checkLocationEnabled(): Promise<void> {
    this.logger.info('Checking if location is enabled...')

    try {
      const locationEnabled = await geoLocationManager.isLocationEnabled()
      if (!locationEnabled) {
        throw new Error('Location service is disabled')
      }

      this.logger.info('Location service is enabled')
    } catch (error) {
      this.logger.error('Failed to check location enabled status', error)
      throw error
    }
  }

  /**
   * 创建定位请求
   */
  private async createLocationRequest(): Promise<void> {
    this.logger.info('Creating location request...')

    try {
      this.locationRequest = {
        priority: this.getPriorityFromAccuracy(),
        interval: this.config.updateInterval,
        expiration: this.config.timeout
      }

      this.logger.info('Location request created', this.locationRequest)
    } catch (error) {
      this.logger.error('Failed to create location request', error)
      throw error
    }
  }

  /**
   * 根据精度获取优先级
   */
  private getPriorityFromAccuracy(): geoLocationManager.LocationRequestPriority {
    switch (this.config.accuracy) {
      case LocationAccuracy.LOW:
        return geoLocationManager.LocationRequestPriority.ACCURACY_LOW
      case LocationAccuracy.MEDIUM:
        return geoLocationManager.LocationRequestPriority.ACCURACY_LOW
      case LocationAccuracy.HIGH:
        return geoLocationManager.LocationRequestPriority.ACCURACY_HIGH
      case LocationAccuracy.BEST:
        return geoLocationManager.LocationRequestPriority.ACCURACY_HIGH
      default:
        return geoLocationManager.LocationRequestPriority.ACCURACY_HIGH
    }
  }

  /**
   * 获取当前位置
   */
  async getCurrentLocation(): Promise<LocationResult> {
    this.logger.info('Getting current location...')

    if (this.isLocating) {
      throw new Error('Already getting location')
    }

    this.isLocating = true
    this.locationStartTime = Date.now()

    try {
      this.setState(LocationState.SEARCHING)

      // 获取位置
      const location = await this.acquireLocation()

      const result: LocationResult = {
        success: true,
        location: location,
        acquireTime: Date.now() - this.locationStartTime
      }

      this.currentLocation = location
      this.setState(LocationState.LOCATED)
      this.notifyLocationChanged(location)

      this.logger.info('Location acquired successfully', location)
      return result

    } catch (error) {
      this.setState(LocationState.ERROR)
      const locationError = error instanceof Error ? error : new Error(String(error))
      this.logger.error('Failed to get location', error)
      this.notifyLocationError(locationError)

      const result: LocationResult = {
        success: false,
        error: locationError,
        acquireTime: Date.now() - this.locationStartTime
      }

      return result
    } finally {
      this.isLocating = false
    }
  }

  /**
   * 获取位置
   */
  private async acquireLocation(): Promise<LocationData> {
    this.logger.info('Acquiring location...')

    return new Promise((resolve, reject) => {
      try {
        if (!this.locationRequest) {
          reject(new Error('Location request not initialized'))
          return
        }

        // 设置超时
        const timeoutId = setTimeout(() => {
          reject(new Error('Location request timeout'))
        }, this.config.timeout)

        // 获取当前位置
        geoLocationManager.getCurrentLocation(this.locationRequest, (err, location) => {
          clearTimeout(timeoutId)

          if (err) {
            reject(new Error(`Location error: ${err.message}`))
            return
          }

          if (!location) {
            reject(new Error('No location data received'))
            return
          }

          const locationData: LocationData = {
            latitude: location.latitude,
            longitude: location.longitude,
            altitude: location.altitude,
            accuracy: location.accuracy,
            altitudeAccuracy: location.altitudeAccuracy,
            heading: location.direction,
            speed: location.speed,
            timestamp: new Date(location.timeStamp)
          }

          resolve(locationData)
        })

      } catch (error) {
        reject(error)
      }
    })
  }

  /**
   * 开始连续位置更新
   */
  async startLocationUpdates(): Promise<void> {
    this.logger.info('Starting location updates...')

    try {
      if (!this.locationRequest) {
        throw new Error('Location request not initialized')
      }

      this.config.continuousUpdates = true

      // 启动位置更新
      const locationChange = (location: geoLocationManager.Location) => {
        const locationData: LocationData = {
          latitude: location.latitude,
          longitude: location.longitude,
          altitude: location.altitude,
          accuracy: location.accuracy,
          altitudeAccuracy: location.altitudeAccuracy,
          heading: location.direction,
          speed: location.speed,
          timestamp: new Date(location.timeStamp)
        }

        this.currentLocation = locationData
        this.notifyLocationChanged(locationData)
      }

      await geoLocationManager.requestLocationUpdate(this.locationRequest, locationChange)

      this.logger.info('Location updates started')
    } catch (error) {
      this.logger.error('Failed to start location updates', error)
      throw error
    }
  }

  /**
   * 停止位置更新
   */
  async stopLocationUpdates(): Promise<void> {
    this.logger.info('Stopping location updates...')

    try {
      this.config.continuousUpdates = false
      await geoLocationManager.stopLocationUpdate()

      this.logger.info('Location updates stopped')
    } catch (error) {
      this.logger.error('Failed to stop location updates', error)
      throw error
    }
  }

  /**
   * 获取海拔信息
   */
  async getAltitude(): Promise<AltitudeData> {
    this.logger.info('Getting altitude...')

    try {
      // 启动气压传感器
      await this.startPressureSensor()

      // 等待传感器数据
      const altitude = await this.waitForAltitudeData()

      await this.stopPressureSensor()

      this.currentAltitude = altitude
      this.notifyAltitudeChanged(altitude)

      this.logger.info('Altitude acquired successfully', altitude)
      return altitude
    } catch (error) {
      this.logger.error('Failed to get altitude', error)
      throw error
    }
  }

  /**
   * 启动气压传感器
   */
  private async startPressureSensor(): Promise<void> {
    if (this.isPressureSensorActive) {
      return
    }

    this.logger.info('Starting pressure sensor...')

    return new Promise((resolve, reject) => {
      try {
        sensor.on(this.pressureSensor, (data: sensor.SensorEvent) => {
          // 处理气压数据
          this.processPressureData(data)
        })

        this.isPressureSensorActive = true
        resolve()
      } catch (error) {
        reject(error)
      }
    })
  }

  /**
   * 停止气压传感器
   */
  private async stopPressureSensor(): Promise<void> {
    if (!this.isPressureSensorActive) {
      return
    }

    this.logger.info('Stopping pressure sensor...')

    try {
      sensor.off(this.pressureSensor)
      this.isPressureSensorActive = false
    } catch (error) {
      this.logger.error('Failed to stop pressure sensor', error)
    }
  }

  /**
   * 处理气压数据
   */
  private processPressureData(data: sensor.SensorEvent): void {
    try {
      const pressure = data.values[0] // 气压，单位hPa

      // 使用气压计算海拔（简化公式）
      const seaLevelPressure = 1013.25 // 海平面标准气压
      const altitude = 44330 * (1 - Math.pow(pressure / seaLevelPressure, 0.1903))

      const altitudeData: AltitudeData = {
        altitude: Math.round(altitude),
        accuracy: 10, // 气压计精度约10米
        pressure: Math.round(pressure * 100) / 100,
        timestamp: new Date()
      }

      this.currentAltitude = altitudeData
      this.notifyAltitudeChanged(altitudeData)
    } catch (error) {
      this.logger.error('Failed to process pressure data', error)
    }
  }

  /**
   * 等待海拔数据
   */
  private async waitForAltitudeData(): Promise<AltitudeData> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('Altitude data timeout'))
      }, this.config.timeout)

      const checkData = () => {
        if (this.currentAltitude) {
          clearTimeout(timeout)
          resolve(this.currentAltitude)
        } else {
          setTimeout(checkData, 100)
        }
      }

      checkData()
    })
  }

  /**
   * 启动方向传感器
   */
  async startOrientationUpdates(): Promise<void> {
    this.logger.info('Starting orientation updates...')

    if (this.isOrientationSensorActive) {
      return
    }

    try {
      sensor.on(this.orientationSensor, (data: sensor.SensorEvent) => {
        this.processOrientationData(data)
      })

      this.isOrientationSensorActive = true
      this.logger.info('Orientation updates started')
    } catch (error) {
      this.logger.error('Failed to start orientation updates', error)
      throw error
    }
  }

  /**
   * 停止方向传感器
   */
  async stopOrientationUpdates(): Promise<void> {
    if (!this.isOrientationSensorActive) {
      return
    }

    this.logger.info('Stopping orientation updates...')

    try {
      sensor.off(this.orientationSensor)
      this.isOrientationSensorActive = false
    } catch (error) {
      this.logger.error('Failed to stop orientation updates', error)
    }
  }

  /**
   * 处理方向数据
   */
  private processOrientationData(data: sensor.SensorEvent): void {
    try {
      // 传感器数据：azimuth, pitch, roll
      const azimuth = data.values[0] // 方位角
      const pitch = data.values[1]   // 俯仰角
      const roll = data.values[2]    // 翻滚角

      const orientationData: OrientationData = {
        azimuth: Math.round(azimuth),
        pitch: Math.round(pitch),
        roll: Math.round(roll),
        timestamp: new Date(),
        accuracy: 5 // 方向传感器精度约5度
      }

      this.currentOrientation = orientationData
      this.notifyOrientationChanged(orientationData)
    } catch (error) {
      this.logger.error('Failed to process orientation data', error)
    }
  }

  /**
   * 地址逆编码
   */
  async reverseGeocode(latitude: number, longitude: number): Promise<LocationAddress | null> {
    this.logger.info('Reverse geocoding...', { latitude, longitude })

    try {
      // 这里需要使用地理编码服务
      // 由于HarmonyOS的地理编码API限制，这里返回模拟数据
      const address: LocationAddress = {
        country: '中国',
        province: '北京市',
        city: '北京市',
        district: '海淀区',
        street: '中关村大街',
        formattedAddress: '北京市北京市海淀区中关村大街'
      }

      this.logger.info('Reverse geocoding completed', address)
      return address
    } catch (error) {
      this.logger.error('Failed to reverse geocode', error)
      return null
    }
  }

  /**
   * 配置定位服务
   */
  configure(config: Partial<LocationConfig>): void {
    this.config = { ...this.config, ...config }
    this.logger.info('Location configuration updated', this.config)

    // 如果定位请求已创建，需要重新创建
    if (this.locationRequest) {
      this.createLocationRequest().catch(error => {
        this.logger.error('Failed to recreate location request', error)
      })
    }
  }

  /**
   * 设置监听器
   */
  setListeners(listeners: LocationListeners): void {
    this.listeners = { ...this.listeners, ...listeners }
  }

  /**
   * 设置状态
   */
  private setState(state: LocationState): void {
    const oldState = this.currentState
    this.currentState = state
    this.logger.info('Location state changed', { from: oldState, to: state })
  }

  /**
   * 通知位置变化
   */
  private notifyLocationChanged(location: LocationData): void {
    if (this.listeners.onLocationChanged) {
      try {
        this.listeners.onLocationChanged(location)
      } catch (error) {
        this.logger.error('Error in location changed callback', error)
      }
    }
  }

  /**
   * 通知位置错误
   */
  private notifyLocationError(error: Error): void {
    if (this.listeners.onLocationError) {
      try {
        this.listeners.onLocationError(error)
      } catch (callbackError) {
        this.logger.error('Error in location error callback', callbackError)
      }
    }
  }

  /**
   * 通知方向变化
   */
  private notifyOrientationChanged(orientation: OrientationData): void {
    if (this.listeners.onOrientationChanged) {
      try {
        this.listeners.onOrientationChanged(orientation)
      } catch (error) {
        this.logger.error('Error in orientation changed callback', error)
      }
    }
  }

  /**
   * 通知海拔变化
   */
  private notifyAltitudeChanged(altitude: AltitudeData): void {
    if (this.listeners.onAltitudeChanged) {
      try {
        this.listeners.onAltitudeChanged(altitude)
      } catch (error) {
        this.logger.error('Error in altitude changed callback', error)
      }
    }
  }

  /**
   * 获取当前位置
   */
  getCurrentLocationData(): LocationData | null {
    return this.currentLocation ? { ...this.currentLocation } : null
  }

  /**
   * 获取当前方向
   */
  getCurrentOrientation(): OrientationData | null {
    return this.currentOrientation ? { ...this.currentOrientation } : null
  }

  /**
   * 获取当前海拔
   */
  getCurrentAltitude(): AltitudeData | null {
    return this.currentAltitude ? { ...this.currentAltitude } : null
  }

  /**
   * 获取定位状态
   */
  getState(): LocationState {
    return this.currentState
  }

  /**
   * 检查是否正在定位
   */
  isLocatingLocation(): boolean {
    return this.isLocating
  }

  /**
   * 获取定位统计信息
   */
  getLocationStats(): {
    state: LocationState
    isLocating: boolean
    hasLocation: boolean
    hasOrientation: boolean
    hasAltitude: boolean
    config: LocationConfig
  } {
    return {
      state: this.currentState,
      isLocating: this.isLocating,
      hasLocation: this.currentLocation !== null,
      hasOrientation: this.currentOrientation !== null,
      hasAltitude: this.currentAltitude !== null,
      config: { ...this.config }
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    this.logger.info('Releasing LocationService resources...')

    try {
      // 停止位置更新
      if (this.config.continuousUpdates) {
        await this.stopLocationUpdates()
      }

      // 停止传感器
      await this.stopOrientationUpdates()
      await this.stopPressureSensor()

      // 清理状态
      this.currentLocation = null
      this.currentOrientation = null
      this.currentAltitude = null
      this.locationRequest = null
      this.setState(LocationState.DISABLED)

      this.logger.info('LocationService resources released successfully')
    } catch (error) {
      this.logger.error('Failed to release LocationService resources', error)
    }
  }
}
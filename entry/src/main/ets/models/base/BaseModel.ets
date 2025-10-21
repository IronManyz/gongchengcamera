/**
 * 基础模型类
 * 所有数据模型的基类，提供通用的属性和方法
 */

@ObservedV2
export class BaseModel {
  @Trace id: string = ''
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()
  @Local version: number = 1

  /**
   * 生成唯一ID
   */
  static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2)
  }

  /**
   * 更新时间戳
   */
  updateTimestamp(): void {
    this.updatedAt = new Date()
  }

  /**
   * 增加版本号
   */
  incrementVersion(): void {
    this.version++
    this.updateTimestamp()
  }

  /**
   * 验证模型是否有效
   */
  isValid(): boolean {
    return this.id.length > 0
  }

  /**
   * 转换为JSON对象
   */
  toJSON(): Record<string, any> {
    return {
      id: this.id,
      createdAt: this.createdAt.getTime(),
      updatedAt: this.updatedAt.getTime(),
      version: this.version
    }
  }

  /**
   * 从JSON对象创建实例
   */
  static fromJSON<T extends BaseModel>(this: new () => T, data: Record<string, any>): T {
    const instance = new this()
    if (data.id) instance.id = data.id
    if (data.createdAt) instance.createdAt = new Date(data.createdAt)
    if (data.updatedAt) instance.updatedAt = new Date(data.updatedAt)
    if (data.version) instance.version = data.version
    return instance
  }

  /**
   * 深度克隆对象
   */
  clone(): this {
    const cloned = Object.create(Object.getPrototypeOf(this))
    Object.assign(cloned, this)
    cloned.createdAt = new Date(this.createdAt)
    cloned.updatedAt = new Date(this.updatedAt)
    return cloned
  }

  /**
   * 比较两个对象是否相等（基于ID）
   */
  equals(other: BaseModel): boolean {
    return other && this.id === other.id
  }

  /**
   * 获取对象的字符串表示
   */
  toString(): string {
    return `${this.constructor.name}(id=${this.id})`
  }
}
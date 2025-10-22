/**
 * 基础模型类
 * 所有数据模型的基类，提供通用的属性和方法
 */

@ObservedV2
export class BaseModel {
  @Trace id: string = ''
  @Trace createdAt: Date = new Date()
  @Trace updatedAt: Date = new Date()
  version: number = 1

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
  toJSON(): BaseModelJSON {
    return {
      id: this.id,
      createdAt: this.createdAt.getTime(),
      updatedAt: this.updatedAt.getTime(),
      version: this.version
    }
  }

  /**
   * 从JSON对象填充基础字段
   * 子类应该重写此方法并调用 super.fromJSONBase(data)
   */
  protected fromJSONBase(data: BaseModelJSON): void {
    if (data.id) this.id = data.id
    if (data.createdAt) this.createdAt = new Date(data.createdAt)
    if (data.updatedAt) this.updatedAt = new Date(data.updatedAt)
    if (data.version) this.version = data.version
  }

  /**
   * 深度克隆对象
   */
  clone(): BaseModel {
    const cloned = new BaseModel()
    cloned.id = this.id
    cloned.createdAt = new Date(this.createdAt)
    cloned.updatedAt = new Date(this.updatedAt)
    cloned.version = this.version
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
    return `BaseModel(id=${this.id})`
  }
}

/**
 * BaseModel JSON 接口
 */
interface BaseModelJSON {
  id: string
  createdAt: number
  updatedAt: number
  version: number
}
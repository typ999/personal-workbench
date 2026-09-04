# Tasks

> 两条原则：① 每个任务两端同步（desktop + mobile CONFIG 与 :root 一致）；② 优先实现核心引擎，再逐模块补功能。

## Phase 0 — 核心基础设施（全局引擎）

- [x] Task 1: 实现金币激励机制引擎 (desktop)
  - [x] SubTask 1.1: coins 数据结构已加入 store.load()
  - [x] SubTask 1.2: awardCoins 函数含日/周封顶
  - [x] SubTask 1.3: 发币函数已定义，触发点待各模块接入
  - [x] SubTask 1.4: celebrateCoin 弹窗庆祝已实现
  - [x] SubTask 1.5: coinTileHTML 首页展示金币+账户

- [x] Task 2: 实现五账户体系 (desktop)
  - [x] SubTask 2.1: accounts 结构已加入 store.load()
  - [x] SubTask 2.2: resetMonthlyQuota 月额度=天数×50
  - [x] SubTask 2.3: canSpendDaily/spendDaily 耗尽校验
  - [x] SubTask 2.4: wishlistExchange 心愿兑换
  - [x] SubTask 2.5: coinTileHTML 五账户速览

- [x] Task 3: 实现徽章系统 (desktop)
  - [x] SubTask 3.1: __badges 结构已加入 store.load()
  - [x] SubTask 3.2: BADGES 8种判定逻辑
  - [x] SubTask 3.3: showBadgeUnlock 弹窗特效

- [x] Task 4: 实现数据导出/导入 (desktop)
  - [x] SubTask 4.1: exportJSON 全量导出
  - [x] SubTask 4.2: importJSON 导入+确认
  - [x] SubTask 4.3: exportCSV 扁平化+clearAllData+storageUsed

- [x] Task 5: 实现暗色模式 (desktop)
  - [x] SubTask 5.1: [data-theme="dark"] 深森林墨绿色板
  - [x] SubTask 5.2: getTheme/applyTheme/toggleTheme 三态
  - [x] SubTask 5.3: prefers-color-scheme 监听

- [x] Task 6: PWA 支持 (desktop)
  - [x] SubTask 6.1: manifest.json 创建
  - [x] SubTask 6.2: sw.js 离线缓存
  - [x] SubTask 6.3: HTML manifest link + SW 注册

## Phase 1 — 今日中枢增强

- [x] Task 7: 天气功能
  - [x] SubTask 7.1: 天气入口按钮（问候区右侧），点击弹出详情卡片

  - [x] SubTask 7.2: 天气详情卡片（温度/湿度/AQI/紫外线 + 穿衣/出行建议）

  - [x] SubTask 7.3: MVP 手动录入天气数据 + 3 小时缓存

- [x] Task 8: 每日学习四项打卡
  - [x] SubTask 8.1: 首页渲染四项卡片（科技/理财/新闻/认知），点击即完成显示 ✓

  - [x] SubTask 8.2: 每日 0:00 自动重置（日期对比）

  - [x] SubTask 8.3: "⚙️ 管理学习项"弹窗（增删改名称/图标）

  - [x] SubTask 8.4: 四项全完成 → 0.5 金币

- [x] Task 9: 待办速览 + 今日开销 + 月额度进度条
  - [x] SubTask 9.1: 首页待办速览区从 todo 模块实时读取今日待办进度

  - [x] SubTask 9.2: 今日开销从 accounts 读取当日可变支出合计

  - [x] SubTask 9.3: 月额度进度条（已用/总额）

## Phase 2 — 每日计划/待办聚合

- [x] Task 10: 全模块待办聚合
  - [x] SubTask 10.1: 植物养护到期 → 自动生成 🌱 前缀待办

  - [x] SubTask 10.2: 目标管理每日学习计划 → 自动生成 🎯 前缀待办

  - [x] SubTask 10.3: 项目看板高优先级 → 自动生成 📊 前缀待办

  - [x] SubTask 10.4: 智能提醒到期 → 自动生成 ⏰ 前缀待办

  - [x] SubTask 10.5: 手动添加 → 📝 前缀待办

- [x] Task 11: 分类筛选 + 优先级 + 完成锁定
  - [x] SubTask 11.1: 分类筛选标签（全部/各来源/自定义）

  - [x] SubTask 11.2: 优先级三级排序（高>中>低），超时标红

  - [x] SubTask 11.3: 完成锁定机制（完成后不可编辑但可取消）

  - [x] SubTask 11.4: 待办全完成 → 1 金币（周封顶 7）

  - [x] SubTask 11.5: 每周日生成上周完成率回顾

## Phase 3 — 健康生活细化

- [x] Task 12: 运动记录 + 自定义类型
  - [x] SubTask 12.1: 运动类型管理弹窗（增删改：名称+emoji+消耗系数），预设 6 类型不可删

  - [x] SubTask 12.2: 运动记录（类型+时长+距离+自动算热量），周/月趋势统计

  - [x] SubTask 12.3: 运动消耗热量同步到减脂模块

  - [x] SubTask 12.4: 每次运动 → 0.5 金币（日封顶 1）

- [x] Task 13: 减脂追踪
  - [x] SubTask 13.1: 体重+体脂率+目标体重记录

  - [x] SubTask 13.2: 体重趋势折线图（30 天）

  - [x] SubTask 13.3: 热量缺口=消耗(运动+基础代谢)-摄入(厨房同步)

- [x] Task 14: 厨房助手四子功能
  - [x] SubTask 14.1: 食材管理（名称+数量+保质期+存放位置+分类，保质期追踪标橙/标红，库存预警）

  - [x] SubTask 14.2: 菜谱推荐（基于现有食材匹配+缺失食材清单+用时/难度/热量估算）

  - [x] SubTask 14.3: 购物清单（从菜谱缺失食材生成+手动添加+勾选已购+购买后一键入库）

  - [x] SubTask 14.4: 营养追踪（每日摄入汇总+三大营养素比例+周/月趋势图，同步到减脂）

## Phase 4 — 植物养护二级页面

- [x] Task 15: 植物总览（一级页面）
  - [x] SubTask 15.1: 植物卡片列表（名称+种植日期+成长天数+状态图标+养护倒计时）

  - [x] SubTask 15.2: 空状态引导插画 + 添加入口

  - [x] SubTask 15.3: 点击卡片进入二级详情页

- [x] Task 16: 植物详情（二级页面）
  - [x] SubTask 16.1: 照片九宫格相册区

  - [x] SubTask 16.2: 时间轴日记（日期倒序，含操作标签+动态反馈图标）

  - [x] SubTask 16.3: 成长分析情感文案（根据记录频率和反馈图标）

  - [x] SubTask 16.4: 7 种动态反馈图标（🌱🌿🪷🍂🪴🍁🥀）

  - [x] SubTask 16.5: 落叶/枯萎 → 次日生成急救养护待办

## Phase 5 — 目标管理增强

- [x] Task 17: 里程碑 + 学习计划 + 倒计时
  - [x] SubTask 17.1: 里程碑拆分（名称+完成状态标记）

  - [x] SubTask 17.2: 每日/每周学习时长目标 → 自动生成每日计划学习待办

  - [x] SubTask 17.3: 考试倒计时（30 天内标橙）

  - [x] SubTask 17.4: 模拟考成绩记录 + 薄弱章节分析

  - [x] SubTask 17.5: 里程碑完成 → 2 金币

## Phase 6 — 灵感补给站

- [x] Task 18: 子分类 + 每日知识 + 阅读计时
  - [x] SubTask 18.1: 子分类切换标签（每日知识/好书/名句/电影/解读/理财串珠）

  - [x] SubTask 18.2: 每日知识推送（每日 2 新+前日 2 条，右侧完整文章展示）

  - [x] SubTask 18.3: 阅读计时（停留 30s + 标记已读 → 0.5 金币，日封顶 2）

- [x] Task 19: 好词好句摘抄子页面
  - [x] SubTask 19.1: 独立子页面（分类筛选：励志/哲思/爱情/古诗词/生活）

  - [x] SubTask 19.2: 关键词全文搜索

  - [x] SubTask 19.3: 导出 TXT（全部或当前筛选）

## Phase 7 — 财富工坊增强

- [x] Task 20: 花销分析图表 + 心愿兑换
  - [x] SubTask 20.1: 周/月支出趋势折线图

  - [x] SubTask 20.2: 月度支出结构饼图（餐饮/交通/日用/娱乐占比）

  - [x] SubTask 20.3: 心愿兑换流程（金币→心愿余额）

  - [x] SubTask 20.4: 省钱奖励阶梯制判定

  - [x] SubTask 20.5: 实时金价展示（MVP 手动录入+走势）

## Phase 8 — 时光胶囊

- [x] Task 21: 情侣日记天数计算 + 日历视图
  - [x] SubTask 21.1: "在一起 XXX 天"+ "距下一个纪念日 XX 天"自动计算，开始时间可改

  - [x] SubTask 21.2: 5 种心情标签筛选，回忆精选 🌟 珍藏

  - [x] SubTask 21.3: 日历视图（有记录日期 ❤️ 标记）

- [x] Task 22: 备忘录 4 分类 + 手绘工具
  - [x] SubTask 22.1: 备忘录 4 分类（学习/生活/灵感/其他）+ 富文本 + 照片 + 标签 + 置顶 + 搜索 + 导出

  - [x] SubTask 22.2: 手绘半屏画板（12 色+吸管+4 画笔+3 粗细+图形/文字工具+10 步撤销+3 背景+导出 PNG）

  - [x] SubTask 22.3: 手绘可在备忘录和情侣日志中调用

- [x] Task 23: 打卡记录
  - [x] SubTask 23.1: 美食/场景/生活足迹打卡（照片+文字+地点+评分+时间线）

## Phase 9 — 智能提醒中心

- [x] Task 24: 三 Tab + 提醒类型 + 日历视图
  - [x] SubTask 24.1: 三 Tab（待处理/即将到来/历史）

  - [x] SubTask 24.2: 提醒类型（生日农历/公历年重复+提前 N 天、定期联系周/月、自定义一次性/每日/每周/每月/每年）

  - [x] SubTask 24.3: 日历视图（月历标记有提醒日期，点击查看当日列表）

  - [x] SubTask 24.4: 到期提醒自动转每日计划待办

  - [x] SubTask 24.5: Web Push API（MVP 降级站内通知）

## Phase 10 — 成就殿堂

- [x] Task 25: 金币明细图表 + 徽章墙 + 金币商城 + 周报
  - [x] SubTask 25.1: 本周金币明细柱状图（待办/学习/省钱/运动/目标/组合技）

  - [x] SubTask 25.2: 金币走势近 7 周折线图

  - [x] SubTask 25.3: 徽章墙（8 种，已解锁高亮+未解锁灰显，解锁弹窗）

  - [x] SubTask 25.4: 金币商城（预设 5 品类+自定义心愿，金币兑换）

  - [x] SubTask 25.5: 周报卡片（每周日生成：金币总数+最高单项+连续天数+雷达图，一键保存）

## Phase 11 — 项目看板

- [x] Task 26: 看板拖拽 + 自定义列
  - [x] SubTask 26.1: 看板三列布局（待办/进行中/已完成，可加自定义列）

  - [x] SubTask 26.2: 任务卡片拖拽跨列移动（HTML5 Drag API）

  - [x] SubTask 26.3: 高优先级自动汇总到今日待办

## Phase 12 — 工作笔记 + 设置

- [x] Task 27: 工作笔记三栏 + 工作备忘
  - [x] SubTask 27.1: 三栏布局（笔记本目录树+笔记列表+编辑/预览区）

  - [x] SubTask 27.2: Markdown 编辑 + 全文搜索 + 版本历史

  - [x] SubTask 27.3: 工作备忘功能（从时光胶囊迁入，快速记录+标签+置顶+导出）

  - [x] SubTask 27.4: 与目标管理学习笔记打通

- [x] Task 28: 设置页功能化
  - [x] SubTask 28.1: 账户设置（头像/昵称编辑）

  - [x] SubTask 28.2: 数据管理（导出 JSON/CSV、导入、清空、存储空间）

  - [x] SubTask 28.3: 外观（日间/夜间/跟随系统+字号调节+导航折叠记忆）

  - [x] SubTask 28.4: 通知开关（各提醒开关+时间设置+每月 1 日备份提醒）

  - [x] SubTask 28.5: 关于（版本号+更新日志+PWA 安装引导）

## Phase 13 — 首页 hero 图 + 收尾

- [x] Task 29: 生成首页 hero 图
  - [x] SubTask 29.1: 调用 GenerateImage 生成鼠尾草绿风格 hero 图，存 assets/greet-banner.jpg

  - [x] SubTask 29.2: 两端 :root --greet-image 指向新图

- [x] Task 30: 两端一致性校验 + 全量功能验证
  - [x] SubTask 30.1: desktop 与 mobile CONFIG 结构一致

  - [x] SubTask 30.2: :root 色板两端一致

  - [x] SubTask 30.3: 全量功能走查（对照 checklist.md）

# Task Dependencies

- Task 1（金币引擎）→ 被 Task 8/11/12/17/18/20/25 依赖

- Task 2（五账户）→ 被 Task 9/20 依赖

- Task 3（徽章）→ 被 Task 25 依赖

- Task 10（待办聚合）→ 依赖 Task 15（植物）/17（目标）/26（看板）/24（提醒）

- Task 13（减脂）→ 依赖 Task 12（运动消耗）/14（营养摄入）

- Task 14（厨房）→ SubTask 14.4 依赖 Task 13（减脂同步）

- Task 22（手绘）→ 独立，可并行

- Task 5（暗色模式）/Task 6（PWA）/Task 4（导出导入）→ 独立，可并行

- Phase 0 全部 → Phase 1-12 的前置

- Task 30（收尾）→ 依赖所有前置任务完成


---
title: 全局 fixed 背景层需要壳层显式建立层级
order: 2
impact: MEDIUM
impactDescription: 避免「DOM 渲染成功但整页空白」的假空白问题
tags: style, stacking-context, z-index, fixed, layout
---

## 全局 `fixed` 背景层需要壳层显式建立 stacking context

当主题系统在根层通过 portal 挂载全屏 `fixed` 背景（星空 canvas、装饰层）时，
业务内容所在的每个一级路由壳层**必须显式声明自己的层级契约**。

不要依赖「内容在 DOM 里写得更靠后所以应该在上面」——
`fixed` 元素会创建新的 stacking context，DOM 顺序在这里不决定结果。

**Incorrect（内容被不透明背景整层盖住）：**

```tsx
// app/admin/layout.tsx
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-(--color-admin-content-bg)">
      <AdminHeader />
      <main>{children}</main>
    </div>
  )
}
```

症状：页面实际渲染成功、DOM 里能看到内容，但**屏幕上是空白的**。

**Correct（壳层根节点显式建立层级）：**

```tsx
// app/admin/layout.tsx
export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="admin-layout-shell relative z-[1] flex min-h-screen flex-col bg-(--color-admin-content-bg)">
      <AdminHeader />
      <main className="admin-layout-main flex-1">{children}</main>
    </div>
  )
}
```

**配套要求**：

- 根层背景如果是 `fixed` 且覆盖全屏，**每个**一级壳层
  （`(viewer)`、`admin`、`login`）都要加 `relative` + 非默认 `z-index`
- 新增或改造全局背景层时，**同时检查所有 sibling layout**，
  而不是只验证当前正在改的那个页面组
- 给一级壳层补回归测试，锁定根容器的语义 class 与层级 class

**为什么值得单列**：这类问题的排查成本极高 ——
DevTools 里能看到元素、能选中、有尺寸，但看不见。
真正原因在另一个文件的 `fixed` 背景层上。

Reference: [MDN: Stacking context](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Understanding_z-index/Stacking_context)

---
title: 异步确认弹框不能点击即关闭
order: 6
impact: HIGH
impactDescription: 失败时用户不会丢失操作上下文，可以原地重试
tags: component, dialog, confirm, async, pending
---

## 异步确认弹框：`preventDefault` + pending 禁用 + 失败保留

删除、覆盖配置、批量初始化这类需要确认的操作：

- **禁止**用 `window.confirm` / `window.alert` —— 无法适配主题，且阻断主线程
- 用受控的 `AlertDialog`（Radix 封装）
- 确认按钮触发异步动作时，**`onClick` 必须 `event.preventDefault()`** ——
  否则 Radix 会在请求完成前自动关闭弹框
- 异步成功后由业务代码显式关闭；**失败时保留弹框**
- **`pending` 来自统一外壳**（`useAsyncAction`），**不要**为弹框自建 `deleting` / `isDeleting` ——
  自建就等于在组件里裸写状态机，见 `action-single-wrapper` 与 `state-loading-vs-pending`
- pending 期间禁用取消与确认按钮，确认按钮显示进行中文案

**Incorrect（点击即关闭，失败后无上下文）：**

```tsx
async function handleDelete(item: Item) {
  if (!window.confirm(`确认删除 ${item.name}？`)) return
  await deleteItem(item.id)          // 失败了用户只看到弹框关掉、什么也没发生
}
```

**Correct（受控 + 走统一外壳 + 失败保留）：**

```tsx
// 删除是「动作」，走统一外壳（见 action-single-wrapper）—— pending 由它管
const { pending, error, run } = useAsyncAction('删除失败')

function handleConfirmDelete(event: React.MouseEvent<HTMLButtonElement>) {
  event.preventDefault()                    // 阻止 Radix 自动关闭
  if (deleteTarget && !pending) {
    void handleDelete(deleteTarget)
  }
}

async function handleDelete(item: Item) {
  if (await run(() => deleteItem(item.id))) {
    setDeleteTarget(null)                   // 只有成功才关
  }
}

<AlertDialog
  open={deleteTarget !== null}
  onOpenChange={(open) => {
    if (!open && !pending) setDeleteTarget(null)     // pending 期间不允许关闭
  }}
>
  <AlertDialogContent>
    <AlertDialogTitle>确认删除「{deleteTarget?.name}」？</AlertDialogTitle>
    <AlertDialogDescription>删除后无法直接恢复。</AlertDialogDescription>
    {error && <p className="text-destructive">{error}</p>}   {/* 失败时保留弹框并就地显示原因 */}
    <AlertDialogFooter>
      <AlertDialogCancel disabled={pending}>取消</AlertDialogCancel>
      <AlertDialogAction disabled={pending} onClick={handleConfirmDelete}>
        {pending ? '删除中…' : '确认删除'}
      </AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

**为什么值得单列**：这是「错误就地显示」在弹框场景的延伸 ——
操作失败后用户必须还能看到原因、还能原地重试，而不是被迫重新找入口。

Reference: [Radix UI: Alert Dialog](https://www.radix-ui.com/primitives/docs/components/alert-dialog)

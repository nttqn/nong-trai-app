// Pure decision for cloud save: given this device's farm and the copy in
// the signed-in account, what to do. Kept free of Firebase for testing.

enum SyncAction { none, upload, restore, ask }

class SaveInfo {
  final int savedAt; // ms since epoch
  final int level, xp;
  const SaveInfo(this.savedAt, this.level, this.xp);
  int get score => level * 1000000 + xp;
}

/// [local]: the farm on this device. [mine]: it already belongs to the
/// signed-in account (synced with it before). [syncedAt]: savedAt of the
/// last copy this device uploaded or restored for that account (0 = never).
/// [cloud]: the account's copy, null when it has none.
SyncAction planSync({
  required SaveInfo local,
  required bool mine,
  required int syncedAt,
  required SaveInfo? cloud,
}) {
  final plan = _plan(local: local, mine: mine, syncedAt: syncedAt, cloud: cloud);
  // Never let a smaller farm silently replace a bigger one (a failed load
  // once showed a fresh farm, which was then uploaded over a level-19 one).
  if (cloud != null) {
    if (plan == SyncAction.upload && cloud.level > local.level) return SyncAction.ask;
    if (plan == SyncAction.restore && cloud.level < local.level) return SyncAction.ask;
  }
  return plan;
}

SyncAction _plan({
  required SaveInfo local,
  required bool mine,
  required int syncedAt,
  required SaveInfo? cloud,
}) {
  if (cloud == null) return SyncAction.upload;
  if (!mine) {
    // First sign-in on this device. A farm barely started here is not
    // worth a question: take the account's farm. Otherwise ask, unless the
    // two are the same save.
    if (cloud.savedAt == local.savedAt) return SyncAction.none;
    if (local.level <= 2 && cloud.score >= local.score) return SyncAction.restore;
    return SyncAction.ask;
  }
  if (cloud.savedAt == local.savedAt) return SyncAction.none;
  if (cloud.savedAt < local.savedAt) {
    // This device is ahead, unless the cloud moved on from a copy older
    // than the one this device last knew (another phone saved meanwhile
    // with a clock behind ours) - then both changed: ask.
    return cloud.savedAt == syncedAt || syncedAt == 0 ? SyncAction.upload : SyncAction.ask;
  }
  // The cloud is newer (played on another device). Take it if nothing
  // changed here since the last sync, otherwise both changed: ask.
  return local.savedAt <= syncedAt ? SyncAction.restore : SyncAction.ask;
}

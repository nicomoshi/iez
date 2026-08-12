#!/usr/bin/env bash

# Collision-safe local notification fixtures bound to one release lifecycle.

notification_fixture_init_identity() {
  local token="${1:-}" compact=""
  [[ "$token" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  compact="${token//-/}"
  NOTIFICATION_FIXTURE_TOKEN="$token"
  NOTIFICATION_FIXTURE_ID="iez-notification-$compact"
  NOTIFICATION_BACKUP_TABLE="notifications_iez_$compact"
  NOTIFICATION_BACKUP_OWNER_TABLE="iez_notif_owner_$compact"
  NOTIFICATION_FIXTURE_TITLE="IEZ check-in $compact"
}

notification_fixture_table_exists() {
  local db_path="$1" table="$2"
  [ -f "$db_path" ] || return 1
  [ "$(sqlite3 "$db_path" "select count(*) from sqlite_master where type='table' and name='$table';" 2>/dev/null)" = "1" ]
}

notification_fixture_row_is_owned() {
  local db_path="$1" token="$2"
  notification_fixture_init_identity "$token" || return 1
  notification_fixture_table_exists "$db_path" notifications || return 1
  [ "$(sqlite3 "$db_path" \
    "select count(*) from notifications where id='$NOTIFICATION_FIXTURE_ID' and json_extract(data, '\$.iezFixtureToken')='$token';" \
    2>/dev/null)" = "1" ]
}

notification_fixture_insert_row() {
  local db_path="$1" token="$2" user_id="$3" group_id="$4" payload="" now_ms=""
  notification_fixture_init_identity "$token" || return 1
  [[ "$user_id" =~ ^[A-Za-z0-9_-]+$ ]] && [[ "$group_id" =~ ^[A-Za-z0-9_-]+$ ]] || return 1
  notification_fixture_table_exists "$db_path" notifications || return 1
  [ "$(sqlite3 "$db_path" "select count(*) from notifications where id='$NOTIFICATION_FIXTURE_ID';" 2>/dev/null)" = "0" ] || return 1
  payload="$(jq -cn --arg groupId "$group_id" --arg token "$token" \
    '{groupId:$groupId,iezFixtureToken:$token}')" || return 1
  payload="${payload//\'/\'\'}"
  now_ms="$(($(date -u +%s) * 1000))"
  sqlite3 "$db_path" <<SQL
begin immediate;
insert into notifications (
  id, user_id, type, title, body, data, is_read, created_at, sync_version
) values (
  '$NOTIFICATION_FIXTURE_ID', '$user_id', 'checkInReminder',
  '$NOTIFICATION_FIXTURE_TITLE', 'Tap to open the matching habit',
  '$payload', 0, $now_ms, 0
);
commit;
SQL
  notification_fixture_row_is_owned "$db_path" "$token"
}

notification_fixture_cleanup_row() {
  local db_path="$1" token="$2"
  notification_fixture_row_is_owned "$db_path" "$token" || return 1
  sqlite3 "$db_path" \
    "delete from notifications where id='$NOTIFICATION_FIXTURE_ID' and json_extract(data, '\$.iezFixtureToken')='$token';" \
    >/dev/null 2>&1 || return 1
  [ "$(sqlite3 "$db_path" "select count(*) from notifications where id='$NOTIFICATION_FIXTURE_ID';" 2>/dev/null)" = "0" ]
}

notification_fixture_backup_is_owned() {
  local db_path="$1" token="$2"
  notification_fixture_init_identity "$token" || return 1
  notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_TABLE" || return 1
  notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_OWNER_TABLE" || return 1
  [ "$(sqlite3 "$db_path" "select count(*) from $NOTIFICATION_BACKUP_OWNER_TABLE where token='$token';" 2>/dev/null)" = "1" ]
}

notification_fixture_create_backup() {
  local db_path="$1" token="$2"
  notification_fixture_init_identity "$token" || return 1
  notification_fixture_table_exists "$db_path" notifications || return 1
  ! notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_TABLE" || return 1
  ! notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_OWNER_TABLE" || return 1
  sqlite3 "$db_path" <<SQL
begin immediate;
create table $NOTIFICATION_BACKUP_OWNER_TABLE (token text primary key not null);
insert into $NOTIFICATION_BACKUP_OWNER_TABLE (token) values ('$token');
alter table notifications rename to $NOTIFICATION_BACKUP_TABLE;
commit;
SQL
  notification_fixture_backup_is_owned "$db_path" "$token"
}

notification_fixture_restore_backup() {
  local db_path="$1" token="$2"
  notification_fixture_backup_is_owned "$db_path" "$token" || return 1
  if notification_fixture_table_exists "$db_path" notifications; then
    sqlite3 "$db_path" <<SQL
begin immediate;
insert or ignore into notifications select * from $NOTIFICATION_BACKUP_TABLE;
drop table $NOTIFICATION_BACKUP_TABLE;
drop table $NOTIFICATION_BACKUP_OWNER_TABLE;
commit;
SQL
  else
    sqlite3 "$db_path" <<SQL
begin immediate;
alter table $NOTIFICATION_BACKUP_TABLE rename to notifications;
drop table $NOTIFICATION_BACKUP_OWNER_TABLE;
commit;
SQL
  fi
  notification_fixture_table_exists "$db_path" notifications || return 1
  ! notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_TABLE" || return 1
  ! notification_fixture_table_exists "$db_path" "$NOTIFICATION_BACKUP_OWNER_TABLE"
}

notification_fixture_drop_backup() {
  local db_path="$1" token="$2"
  notification_fixture_backup_is_owned "$db_path" "$token" || return 1
  sqlite3 "$db_path" \
    "begin immediate; drop table $NOTIFICATION_BACKUP_TABLE; drop table $NOTIFICATION_BACKUP_OWNER_TABLE; commit;" \
    >/dev/null 2>&1
}

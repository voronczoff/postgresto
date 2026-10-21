--liquibase formatted sql
--changeset framework:seed-view-e81c6e4f83 runOnChange:true splitStatements:false
INSERT INTO postgresto.view
  (id, jsondata)
VALUES (
  'public.pg_stat_statements|Default',
  $json$
  {
    "table": "pg_stat_statements",
    "schema": "public",
    "columns": {
      "id": {
        "path": "queryid",
        "type": "number",
        "orderList": 1,
        "searchable": false
      },
      "dbid": {
        "path": "dbid",
        "type": "text",
        "orderList": 3
      },
      "rows": {
        "path": "rows",
        "type": "number",
        "orderList": 18,
        "searchable": false
      },
      "calls": {
        "path": "calls",
        "type": "number",
        "orderList": 12,
        "searchable": false
      },
      "plans": {
        "path": "plans",
        "type": "number",
        "orderList": 6,
        "searchable": false
      },
      "query": {
        "path": "query",
        "type": "text",
        "orderList": 5
      },
      "userid": {
        "path": "userid",
        "type": "text",
        "orderList": 2
      },
      "wal_fpi": {
        "path": "wal_fpi",
        "type": "number",
        "orderList": 36,
        "searchable": false
      },
      "toplevel": {
        "path": "toplevel",
        "type": "boolean",
        "orderList": 4
      },
      "wal_bytes": {
        "path": "wal_bytes",
        "type": "number",
        "orderList": 37,
        "searchable": false
      },
      "stats_since": {
        "path": "stats_since",
        "type": "datetime",
        "orderList": 51
      },
      "wal_records": {
        "path": "wal_records",
        "type": "number",
        "orderList": 35,
        "searchable": false
      },
      "jit_functions": {
        "path": "jit_functions",
        "type": "number",
        "orderList": 39,
        "searchable": false
      },
      "max_exec_time": {
        "path": "max_exec_time",
        "type": "number",
        "orderList": 15,
        "searchable": false
      },
      "max_plan_time": {
        "path": "max_plan_time",
        "type": "number",
        "orderList": 9,
        "searchable": false
      },
      "min_exec_time": {
        "path": "min_exec_time",
        "type": "number",
        "orderList": 14,
        "searchable": false
      },
      "min_plan_time": {
        "path": "min_plan_time",
        "type": "number",
        "orderList": 8,
        "searchable": false
      },
      "local_blks_hit": {
        "path": "local_blks_hit",
        "type": "number",
        "orderList": 23,
        "searchable": false
      },
      "mean_exec_time": {
        "path": "mean_exec_time",
        "type": "number",
        "orderList": 16,
        "searchable": false
      },
      "mean_plan_time": {
        "path": "mean_plan_time",
        "type": "number",
        "orderList": 10,
        "searchable": false
      },
      "temp_blks_read": {
        "path": "temp_blks_read",
        "type": "number",
        "orderList": 27,
        "searchable": false
      },
      "jit_deform_time": {
        "path": "jit_deform_time",
        "type": "number",
        "orderList": 48,
        "searchable": false
      },
      "local_blks_read": {
        "path": "local_blks_read",
        "type": "number",
        "orderList": 24,
        "searchable": false
      },
      "shared_blks_hit": {
        "path": "shared_blks_hit",
        "type": "number",
        "orderList": 19,
        "searchable": false
      },
      "total_exec_time": {
        "path": "total_exec_time",
        "type": "number",
        "orderList": 13,
        "searchable": false
      },
      "total_plan_time": {
        "path": "total_plan_time",
        "type": "number",
        "orderList": 7,
        "searchable": false
      },
      "jit_deform_count": {
        "path": "jit_deform_count",
        "type": "number",
        "orderList": 47,
        "searchable": false
      },
      "shared_blks_read": {
        "path": "shared_blks_read",
        "type": "number",
        "orderList": 20,
        "searchable": false
      },
      "stddev_exec_time": {
        "path": "stddev_exec_time",
        "type": "number",
        "orderList": 17,
        "searchable": false
      },
      "stddev_plan_time": {
        "path": "stddev_plan_time",
        "type": "number",
        "orderList": 11,
        "searchable": false
      },
      "wal_buffers_full": {
        "path": "wal_buffers_full",
        "type": "number",
        "orderList": 38,
        "searchable": false
      },
      "jit_emission_time": {
        "path": "jit_emission_time",
        "type": "number",
        "orderList": 46,
        "searchable": false
      },
      "jit_inlining_time": {
        "path": "jit_inlining_time",
        "type": "number",
        "orderList": 42,
        "searchable": false
      },
      "temp_blks_written": {
        "path": "temp_blks_written",
        "type": "number",
        "orderList": 28,
        "searchable": false
      },
      "jit_emission_count": {
        "path": "jit_emission_count",
        "type": "number",
        "orderList": 45,
        "searchable": false
      },
      "jit_inlining_count": {
        "path": "jit_inlining_count",
        "type": "number",
        "orderList": 41,
        "searchable": false
      },
      "local_blks_dirtied": {
        "path": "local_blks_dirtied",
        "type": "number",
        "orderList": 25,
        "searchable": false
      },
      "local_blks_written": {
        "path": "local_blks_written",
        "type": "number",
        "orderList": 26,
        "searchable": false
      },
      "minmax_stats_since": {
        "path": "minmax_stats_since",
        "type": "datetime",
        "orderList": 52
      },
      "temp_blk_read_time": {
        "path": "temp_blk_read_time",
        "type": "number",
        "orderList": 33,
        "searchable": false
      },
      "jit_generation_time": {
        "path": "jit_generation_time",
        "type": "number",
        "orderList": 40,
        "searchable": false
      },
      "local_blk_read_time": {
        "path": "local_blk_read_time",
        "type": "number",
        "orderList": 31,
        "searchable": false
      },
      "shared_blks_dirtied": {
        "path": "shared_blks_dirtied",
        "type": "number",
        "orderList": 21,
        "searchable": false
      },
      "shared_blks_written": {
        "path": "shared_blks_written",
        "type": "number",
        "orderList": 22,
        "searchable": false
      },
      "temp_blk_write_time": {
        "path": "temp_blk_write_time",
        "type": "number",
        "orderList": 34,
        "searchable": false
      },
      "local_blk_write_time": {
        "path": "local_blk_write_time",
        "type": "number",
        "orderList": 32,
        "searchable": false
      },
      "shared_blk_read_time": {
        "path": "shared_blk_read_time",
        "type": "number",
        "orderList": 29,
        "searchable": false
      },
      "jit_optimization_time": {
        "path": "jit_optimization_time",
        "type": "number",
        "orderList": 44,
        "searchable": false
      },
      "shared_blk_write_time": {
        "path": "shared_blk_write_time",
        "type": "number",
        "orderList": 30,
        "searchable": false
      },
      "jit_optimization_count": {
        "path": "jit_optimization_count",
        "type": "number",
        "orderList": 43,
        "searchable": false
      },
      "parallel_workers_launched": {
        "path": "parallel_workers_launched",
        "type": "number",
        "orderList": 50,
        "searchable": false
      },
      "parallel_workers_to_launch": {
        "path": "parallel_workers_to_launch",
        "type": "number",
        "orderList": 49,
        "searchable": false
      }
    },
    "sorting": [],
    "rowcount": true,
    "selector": true,
    "pkOverride": "queryid"
  }
  $json$::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  jsondata = EXCLUDED.jsondata;

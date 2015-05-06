db = require "lapis.db.mysql"

import Enum, enum, BaseModel, singularize, add_relations
  from require "lapis.db.base_model"

class Model extends BaseModel
  -- create from table of values, return loaded object
  @create: (values, opts) =>
    if @constraints
      for key in pairs @constraints
        if err = @_check_constraint key, values and values[key], values
          return nil, err

    values._timestamp = true if @timestamp

    res = db.insert @table_name!, values, @primary_keys!

    if res
      -- FIXME this code works only if mysql backend is
      -- either luasql (field res.last_auto_id) or
      -- lua-resty-mysql (field res.insert_id) and
      new_id = res.last_auto_id or res.insert_id
      if not values[@primary_key] and new_id
        values[@primary_key] = new_id
      @load values
    else
      nil, "Failed to create #{@__name}"

  -- thing\update "col1", "col2", "col3"
  -- thing\update {
  --   "col1", "col2"
  --   col3: "Hello"
  -- }
  update: (first, ...) =>
    cond = @_primary_cond!

    columns = if type(first) == "table"
      for k,v in pairs first
        if type(k) == "number"
          v
        else
          @[k] = v
          k
    else
      {first, ...}

    return nil, "nothing to update" if next(columns) == nil

    if @@constraints
      for _, column in pairs columns
        if err = @@_check_constraint column, @[column], @
          return nil, err

    values = { col, @[col] for col in *columns }

    -- update options
    nargs = select "#", ...
    last = nargs > 0 and select nargs, ...

    opts = if type(last) == "table" then last

    if @@timestamp and not (opts and opts.timestamp == false)
      values._timestamp = true

    db.update @@table_name!, values, cond

{ :Model, :Enum, :enum }
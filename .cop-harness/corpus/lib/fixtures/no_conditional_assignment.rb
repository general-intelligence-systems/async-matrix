# frozen_string_literal: true

a = if cond
  1
else
  2
end

b = case value
when 1 then :one
else :other
end

c = cond ? :ok : :no

@d = if cond
  1
end

obj.status = cond ? :ok : :pending

e = 1

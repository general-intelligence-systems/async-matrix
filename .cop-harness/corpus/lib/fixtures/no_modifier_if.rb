# frozen_string_literal: true

def one(task)
  call if task
end

def two(task)
  call unless task
end

def three(task)
  if task
    call
  end
end

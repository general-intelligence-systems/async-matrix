# frozen_string_literal: true

def tappable(params)
  column = params[:id].to_s
  check(column)
  column
end

def reassigned(params)
  column = params[:id].to_s
  column = other(column)
  column
end

def not_returned(params)
  column = params[:id].to_s
  check(column)
  nil
end

def self.singleton(params)
  name = params[:name].to_s
  check(name)
  name
end

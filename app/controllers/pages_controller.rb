class PagesController < ApplicationController
  def home
  end

  # Добавляем пустой метод (action).
  # Rails автоматически будет искать файл import.html.erb для этого метода.
  def import
  end
end

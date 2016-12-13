Rails.application.routes.draw do
  mount SftpServer::API => '/'
end

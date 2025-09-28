// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import * as bootstrap from "bootstrap"

import jQuery from "jquery"

window.$ = window.jQuery = jQuery

import("jquery-ui-dist")

console.log("jquery-ui-dist loaded")

import Rails from "rails-ujs"
Rails.start()

console.log("application.js loaded")

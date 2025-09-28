# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "bootstrap", to: "bootstrap.bundle.min.js"
#pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.11
pin "jquery" # @3.7.1
pin "jquery-ui-dist", to: "https://ga.jspm.io/npm:jquery-ui-dist@1.13.1/jquery-ui.js"
pin "rails-ujs" # @5.2.8
pin "lightbox2" # @2.11.5

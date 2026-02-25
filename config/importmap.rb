pin_all_from Rowdy::Engine.root.join("app/javascript/controllers"), under: "controllers/rowdy", to: "controllers"
pin_all_from Rowdy::Engine.root.join("app/javascript/rowdy"), under: "rowdy"
pin "rowdy", to: "rowdy/index.js"

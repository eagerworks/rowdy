pin_all_from Rowdy::Engine.root.join("app/javascript/controllers"), under: "controllers/rowdy", to: "controllers"
pin "rowdy", to: "rowdy/index.js"
pin "rowdy/upload_worker", to: "rowdy/upload_worker.js"

const express = require('express')
const path = require('path')
const serveStatic = require('serve-static')

const app = express()
const port = process.env.PORT || 8081

app.use(serveStatic(__dirname))
app.listen(port)
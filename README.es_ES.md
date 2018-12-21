![NUU Setup and Structure Guide: Phoenix Framework, Webpack Module Bundler, React Library & GraphQL Query Language](images/logo.es_ES.png)
---

Guía para la configuración inicial de proyectos que se construyan con las tecnologías: Framework [Phoenix](https://phoenixframework.org/), Empaquetador de módulos [Webpack](https://webpack.js.org/), Librería [React](https://reactjs.org/) y Lenguaje de Consultas [GraphQL](https://graphql.org/) y cómo se deberá organizar cada elemento en la estructura interna del proyecto.

[![NUU Group Documents](https://img.shields.io/badge/NUU%20Group-Documents-blue.svg)](https://nuu.co/)

## Tabla de Contenido

- [**Preparación Inicial**](#preparación-inicial)
  - [Instrucciones de Instalación](#instrucciones-de-instalación)
  - [Configuración](configuración)
- [**Estructura del Proyecto**](#estructura-del-proyecto)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [**Idiomas**](#idiomas)
- [**Derechos**](#derechos)
  - [Licencia](#licencia)
  - [Atribución](#atribución)

## Preparación Inicial

### Instrucciones de Instalación

Para poder crear proyectos con este grupo de tecnologías es necesario instalar Phoenix en el sistema. Webpack, React y QraphQL se instalarán posteriormente en cada proyecto al configurarlo.

Para saber si ya ha sido instalado Phoenix en el equipo se puede intrucir el siguiente comando en consola:

```bh
mix phx.new --version
```

Si no regresa información de versión, habrá que instalarlo. En la documentación de Phoenix existe una página con las [Instrucciones de instalación](https://hexdocs.pm/phoenix/installation.html).

### Configuración

1. Crear un proyecto nuevo de Phoenix:

    ```bh
    mix phx.new project_name
    ```
    Durante el proceso de creación de archivos se pregunta si se desea extraer e instalar las dependencias para el proyecto, indicar que sí.

1. Acceder al directorio ***project_name\assets*** del proyecto.

    ```bh
    cd project_name\assets
    ```

1. Desinstalar via NPM las siguientes dependencias:

    - brunch
    - babel-brunch
    - clean-css-brunch
    - uglify-js-brunch

    ```bh
    npm uninstall --save-dev babel-brunch brunch clean-css-brunch uglify-js-brunch
    ```

1. Eliminar el archivo ***brunch-config.js***

    ```bh
    rm brunch-config.js
    ```

1. Instalar via NPM las siguientes dependencias:

    - webpack
    - webpack-cli
    - copy-webpack-plugin
    - uglifyjs-webpack-plugin
    - graphql
    - react
    - react-dom
    - react-router-dom
    - prop-types
    - @babel/core
    - @babel/cli
    - @babel/preset-env
    - @babel/preset-react
    - @babel/plugin-proposal-class-properties
    - babel-loader
    - css-loader
    - url-loader
    - file-loader
    - mini-css-extract-plugin
    - optimize-css-assets-webpack-plugin

    ```bh
    npm install --save-dev webpack webpack-cli copy-webpack-plugin uglifyjs-webpack-plugin graphql react react-dom react-router-dom prop-types @babel/core @babel/cli @babel/preset-env @babel/preset-react @babel/plugin-proposal-class-properties babel-loader css-loader url-loader file-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin
    ```
1. Crear un nuevo archivo con ***.babelrc*** como nombre de archivo.

    ```bh
    touch .babelrc
    ```

1. Editar el archivo ***.babelrc*** y colocar el siguiente código:

    ```json
    {
      "presets": [
          ["@babel/preset-env", {"modules" : false}],
          "@babel/preset-react"
        ],
      "plugins": [
          "@babel/plugin-proposal-class-properties"
        ]
    }
    ```

1. Editar el archivo ***package.json*** y substituir el valor de la llave `scripts` con el siguiente código:

    ```json
    "scripts": {
        "deploy": "webpack --mode production",
        "start": "webpack --mode development --watch-stdin --color"
      },
    ```

1. Crear un nuevo archivo con ***webpack.config.js*** como nombre de archivo.

    ```bh
    touch webpack.config.js
    ```

1. Editar el archivo ***webpack.config.js*** y colocar el siguiente código:

    ```js
    const path = require('path');
    const MiniCssExtractPlugin = require('mini-css-extract-plugin');
    const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
    const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
    const CopyWebpackPlugin = require('copy-webpack-plugin');

    module.exports = (env, options) => ({
      optimization: {
        minimizer: [
          new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
          new OptimizeCSSAssetsPlugin({})
        ]
      },
      entry: './js/app.js',
      output: {
        filename: 'app.js',
        path: path.resolve(__dirname, '../priv/static/js')
      },
      module: {
        rules: [
          {
            test: /\.js$/,
            exclude: /node_modules/,
            use: {
              loader: 'babel-loader'
            }
          },
          {
            test: /\.css$/,
            use: [MiniCssExtractPlugin.loader, 'css-loader']
          },
          {
            test: /\.svg$/,
            use: [
              {
                loader: 'file-loader',
                options: {
                  mimetype: 'image/svg+xml',
                  outputPath: '../images',
                  name (file) {
                    if (env === 'development' || env === undefined)
                      return '[name].[ext]'
                    else
                      return '[hash].[ext]'
                  }
                }
              }
            ]
          }
        ]
      },
      plugins: [
        new MiniCssExtractPlugin({ filename: '../css/app.css' }),
        new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
      ]
    });
    ```

1. Acceder al directorio ***project_name\assets\js*** del proyecto.

    ```bh
    cd js
    ```

1. Crear un nuevo archivo con ***index.js*** como nombre de archivo.

    ```bh
    touch index.js
    ```

1. Editar el archivo ***index.js*** y colocar el siguiente código:

    ```jsx
    // Dependencias
    import React, { Component } from 'react';
    import ReactDOM from 'react-dom';

    class App extends Component {
      render() {
        return (
          <div>Ok</div>
        );
      }
    }

    ReactDOM.render(
      <App />,
      document.getElementById('root')
    );
    ```

1. Crear los directorios ***components***, ***pages*** y ***data***.

    ```bh
    mkdir components
    mkdir pages
    mkdir data
    ```

1. Editar el archivo ***app.js*** y después del último `import` agregar el siguiente código:

    ```js
    import css from "../css/app.css"
    import { index } from "./index"
    ```

1. Acceder al directorio ***project_name\config*** del proyecto.

    ```bh
    cd ..\..\config
    ```

1. Editar el archivo ***dev.exs*** y substituir el valor de la llave `watchers` con el siguiente código:

    ```elixir
    watchers: [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color", cd: Path.expand("../assets", __DIR__)]]
    ```

1. Configura en los archivos ***dev.exs*** y ***test.exs*** las credenciales para las bases de datos.

    ```elixir
    config :project_name, ProjectName.Repo,
      adapter: Ecto.Adapters.Postgres,
      username: "postgres",
      password: "pass",
      database: "project_name_dev",
      hostname: "localhost",
      pool_size: 10
    ```

1. Acceder al directorio ***project_name\lib\project_name_web\tamplates\layout*** del proyecto.

    ```bh
    cd ..\lib\project_name_web\templates\layout
    ```

1. Editar el archivo ***app.html.eex*** y substituir el tag `<body>` y su contenido con el siguiente código:

    ```html
    <body>
      <main role="main">
        <%= render @view_module, @view_template, assigns %>
      </main>
      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    </body>
    ```

1. Acceder al directorio ***project_name\lib\project_name_web\tamplates\page*** del proyecto.

    ```bh
    cd ..\page
    ```

1. Editar el archivo ***index.html.eex*** y substituir todo el contenido del archivo con el siguiente código:

    ```html
    <div id="root"></div>
    ```

1. Acceder al directorio raiz del proyecto: ***project_name***

    ```bh
    cd ..\..\..\..
    ```

1. Crear la base de datos del proyecto.

    ```bh
    mix ecto.create
    ```

Para comprobar que se ha configurado correctamente el proyecto se deberá inicializar el servidor con el comando:

```bh
mix phx.server
```

En el explorador ingresar la URL [`localhost:4000`](http://localhost:4000). Si este despliega una página en blanco con un único texto "Ok" y no muestra errores ni advertencias tanto en la consola del servidor como en la del explorador, la configuración ha sido exitosa.

## Estructura del Proyecto

### Backend

*Bajo redacción.*

### Frontend

*Bajo redacción.*

## Idiomas

- [Español](README.es_ES.md)
- [Inglés (English)](README.md)

## Derechos

### Licencia

![Creative Commons License](http://i.creativecommons.org/l/by/3.0/88x31.png) Este documento está publicado bajo licencia [Creative Commons Reconocimiento 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/deed.es_ES).
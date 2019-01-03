
![NUU Setup and Structure Guide: Phoenix Framework, Webpack Module Bundler, React Library & GraphQL Query Language](images/logo.png)
---

Guide for the initial configuration for projects that are built with the following technologies: [Phoenix](https://phoenixframework.org/) Framework, [Webpack](https://webpack.js.org/) Module Bundler, [React](https://reactjs.org/) Library and [GraphQL](https://graphql.org/) Query Language and how each element should be organized in the internal structure of the project.

[![NUU Group Documents](https://img.shields.io/badge/NUU%20Group-Documents-blue.svg)](https://nuu.co/)

## Table of Contents

- [**Initial Setup**](#initial-setup)
  - [Installation Instructions](installation-instructions)
  - [Configuration](configuration)
- [**Project Structure**](#project-structure)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [**Languages**](#languages)
- [**Copying**](#copying)
  - [License](#license)
  - [Attribution](#attribution)

## Initial Setup

### Installation Instructions

To be able to create projects with this stack of technologies it is necessary to install Phoenix on the system. Webpack, React and QraphQL will be installed later on each project when configuring it.

To know if Phoenix has already been installed on the computer, you can enter the following console command:

```bh
mix phx.new --version
```

If this does not return version information, it must have to be installed. In the Phoenix documentation there is a page with the [Installation instructions](https://hexdocs.pm/phoenix/installation.html).

### Configuration

1. Create a new Phoenix project:

    ```bh
    mix phx.new project_name
    ```
    
    During the process of creating files, is asked if you want to extract and install the dependencies for the project, indicate yes.

1. Access to the ***project_name\assets*** directory of the project.

    ```bh
    cd project_name\assets
    ```

1. Uninstall via NPM the following dependencies:

    - brunch
    - babel-brunch
    - clean-css-brunch
    - uglify-js-brunch

    ```bh
    npm uninstall --save-dev babel-brunch brunch clean-css-brunch uglify-js-brunch
    ```

1. Delete the ***brunch-config.js*** file.

    ```bh
    rm brunch-config.js
    ```

1. Install via NPM the following dependencies:

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
1. Create a new file with ***.babelrc*** as file name.

    ```bh
    touch .babelrc
    ```

1. Edit the ***.babelrc*** file and place the following code:

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

1. Edit the ***package.json*** file and replace the value of the `scripts` key with the following code:

    ```json
    "scripts": {
        "deploy": "webpack --mode production",
        "start": "webpack --mode development --watch-stdin --color"
      },
    ```

1. Create a new file with ***webpack.config.js*** as file name.

    ```bh
    touch webpack.config.js
    ```

1. Edit the ***webpack.config.js*** file and place the following code:

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

1. Access to the ***project_name\assets\js*** directory of the project.

    ```bh
    cd js
    ```

1. Create a new file with ***index.js*** as file name.

    ```bh
    touch index.js
    ```

1. Edit the ***index.js*** file and place the following code:

    ```jsx
    // Dependencies
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

1. Create the ***components***, ***pages*** and ***data*** directories.

    ```bh
    mkdir components && mkdir pages && mkdir data
    ```

1. Edit the ***app.js*** file and after the last `import` place the following code:

    ```js
    import css from "../css/app.css"
    import { index } from "./index"
    ```

1. Access to the ***project_name\config*** directory of the project.

    ```bh
    cd ..\..\config
    ```

1. Edit the ***dev.exs*** file and replace the value of the `watchers` key with the following code:

    ```elixir
    watchers: [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color", cd: Path.expand("../assets", __DIR__)]]
    ```

1. Configure in the ***dev.exs*** and ***test.exs*** files the credentials for the databases.

    ```elixir
    config :project_name, ProjectName.Repo,
      adapter: Ecto.Adapters.Postgres,
      username: "postgres",
      password: "pass",
      database: "project_name_dev",
      hostname: "localhost",
      pool_size: 10
    ```

1. Access to the ***project_name\lib\project_name_web\tamplates\layout*** directory of the project.

    ```bh
    cd ..\lib\project_name_web\templates\layout
    ```

1. Edit the ***app.html.eex*** file and replace the tag `<body>` and its content with the following code:

    ```html
    <body>
      <main role="main">
        <%= render @view_module, @view_template, assigns %>
      </main>
      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    </body>
    ```

1. Access to the ***project_name\lib\project_name_web\tamplates\page*** directory of the project.

    ```bh
    cd ..\page
    ```

1. Edit the ***index.html.eex*** file and replace all the content with the following code:

    ```html
    <div id="root"></div>
    ```

1. Access to the root directory of the project: ***project_name***.

    ```bh
    cd ..\..\..\..
    ```

1. Edit the ***mix.exs*** and add the following dependencies:

    ```elixir
    {:plug_cowboy, "~> 1.0"},
    {:absinthe, "~> 1.4.13"},
    {:absinthe_ecto, "~> 0.1.3"},
    {:absinthe_plug, "~> 1.4.6"},
    {:absinthe_phoenix, "~> 1.4.3"}
    ```

    Delete the following dependency in the same file:

    ```elixir
    {:cowboy, "~> 1.0"}
    ```

1. Access to the ***project_name\lib\project_name_web*** directory of the project.

    ```bh
    cd lib\project_name_web
    ```

1. Edit the ***router.ex*** file and add the following code after de last `scope`:

    ```elixir
    if Mix.env == :dev do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: ProjectName.Graphql.Schema,
        interface: :advanced,
        context: %{pubsub: ProjectName.Endpoint}
    end
    ```

    Do not forget to replace the module name `ProjectName` in this code with the actual project name.

1. Access to the ***project_name\lib\project_name*** directory of the project.

    ```bh
    cd ..\project_name
    ```

1. Create the ***graphql*** directory and access it.

    ```bh
    mkdir graphql && cd graphql
    ```

1. Create a new file with ***queries.ex*** as file name.

    ```bh
    touch queries.ex
    ```

1. Edit the ***queries.ex*** file and place the following code:

    ```elixir
    defmodule ProjectName.Graphql.Queries do
      @moduledoc false

      use Absinthe.Schema.Notation

      object :queries do
      end
    end
    ```

    Do not forget to replace the module name `ProjectName` in this code with the actual project name.

1. Create a new file with ***mutations.ex*** as file name.

    ```bh
    touch mutations.ex
    ```

1. Edit the ***mutations.ex*** file and place the following code:

    ```elixir
    defmodule ProjectName.Graphql.Mutations do
      @moduledoc false

      use Absinthe.Schema.Notation

      object :mutations do
      end
    end
    ```

    Do not forget to replace the module name `ProjectName` in this code with the actual project name.

1. Create a new file with ***subscriptions.ex*** as file name.

    ```bh
    touch subscriptions.ex
    ```

1. Edit the ***subscriptions.ex*** file and place the following code:

    ```elixir
    defmodule ProjectName.Graphql.Subscriptions do
      @moduledoc false

      use Absinthe.Schema.Notation

      object :subscriptions do
      end
    end
    ```

    Do not forget to replace the module name `ProjectName` in this code with the actual project name.

1. Create a new file with ***schema.ex*** as file name.

    ```bh
    touch schema.ex
    ```

1. Edit the ***schema.ex*** file and place the following code:

    ```elixir
    defmodule ProjectName.Graphql.Schema do
      @moduledoc false

      use Absinthe.Schema

      import_types ProjectName.Graphql.Queries
      import_types ProjectName.Graphql.Mutations
      import_types ProjectName.Graphql.Subscriptions
      import_types Absinthe.Plug.Types
      import_types Absinthe.Type.Custom

      query [], do: import_fields :queries
      mutation [], do: import_fields :mutations
      subscription [], do: import_fields :subscriptions
    end
    ```

    Do not forget to replace the module name `ProjectName` in this code with the actual project name.

1. Access to the root directory of the project: ***project_name***.

    ```bh
    cd ..\..\..
    ```

1. Update and compile the new dependencies of the Phoenix project.

    ```bh
    mix deps.get && mix deps.compile
    ```

1. Create the project database.

    ```bh
    mix ecto.create
    ```

To verify that the project has been correctly configured, the server must be initialized with the command:

```bh
mix phx.server
```

In the browser enter the URL [`localhost:4000`](http://localhost:4000). If it displays a blank page with a single text "Ok" and shows no errors or warnings in both the server and the browser console, the configuration has been successful.

## Project Structure

### Backend

*Under redaction.*

### Frontend

*Under redaction.*

## Languages

- [English](README.md)
- [Spanish (Español)](README.es_ES.md)

## Copying

### License

![Creative Commons License](http://i.creativecommons.org/l/by/3.0/88x31.png) This work is licensed under a [Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/deed.en_US).
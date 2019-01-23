# -*- ENCODING: UTF-8 -*-
#!/bin/bash
VERSION="v1.0.4"
trap terminate_script SIGINT

# Variables ====================================================================
PROJECT_NAME=""
MODULE=""
TARGET_PATH=""
# Variables de control -------------------------------------------------------
SCRIPT_PID=$$
KERNEL=$(uname -s)
ARGS_COUNT=0
TASK_COUNT=0
TIMELINE_COLOR="\e[1m\e[30m"
TIMELINE_SYMBOL="▌"
TIMELINE_END_SYMBOL="█"
TIMELINE_L_MARGIN=" "
TIMELINE_R_MARGIN=" "
TIMELINE_STEP="${TIMELINE_COLOR}${TIMELINE_L_MARGIN}${TIMELINE_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
CHECK_SYMBOL="\e[32m\e[1m✔\e[0m"
CANCEL_SYMBOL="\e[31m\e[1m✖\e[0m"
# Funciones de Control -------------------------------------------------------

function display_message () {
  local TYPE=$1
  local ARGS_COUNT=0
  if [ "${TYPE}" = "error" ]; then
    local MESSAGE_STEP="\e[31m${TIMELINE_L_MARGIN}${TIMELINE_END_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
    local TITLE=" Error: "
  elif [ "${TYPE}" = "arg_error" ]; then
    local MESSAGE_STEP=""
    local TITLE="Argument error: "
  elif [ "${TYPE}" = "green" ]; then
    local MESSAGE_STEP="\e[32m${TIMELINE_L_MARGIN}${TIMELINE_END_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
    local TITLE=" Done: "
  elif [ "${TYPE}" = "warning" ]; then
    local MESSAGE_STEP="\e[33m${TIMELINE_L_MARGIN}${TIMELINE_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
    local TITLE=" Warning: "
  elif [ "${TYPE}" = "blue" ]; then
    local MESSAGE_STEP="\e[0m${TIMELINE_STEP}"
    local TITLE=" Input: "
  elif [ "${TYPE}" = "task" ]; then
    local MESSAGE_STEP="\e[0m${TIMELINE_STEP}"
    let TASK_COUNT++
    local TITLE=" Task ${TASK_COUNT}: "
  fi
  for ((i=1; i<=${#TITLE}; i++)); do
    local TAB="${TAB} "
  done
  shift
  for VAR in "$@"
  do
    if [ "${ARGS_COUNT}" = "0" ]; then
      local MESSAGE="${VAR}" 
    else
      local MESSAGE="${MESSAGE}\n${MESSAGE_STEP}${TAB}${VAR}" 
    fi
    let ARGS_COUNT++
    shift
  done 
  if [ "${TYPE}" = "error" ]; then
    printf "\n${MESSAGE_STEP}\e[1m\e[31m${TITLE}\e[0m${MESSAGE}"
  elif [ "${TYPE}" = "arg_error" ]; then
    printf "${MESSAGE_STEP}\e[1m\e[31m${TITLE}\e[0m${MESSAGE}\n"
  elif [ "${TYPE}" = "green" ]; then
    printf "\n${MESSAGE_STEP}\e[1m\e[32m${TITLE}\e[0m${MESSAGE}"
  elif [ "${TYPE}" = "warning" ]; then
    printf "\n${MESSAGE_STEP}\e[1m\e[33m${TITLE}\e[0m${MESSAGE}"
  elif [ "${TYPE}" = "blue" ]; then
    printf "\n${MESSAGE_STEP}\e[1m\e[34m${TITLE}\e[0m${MESSAGE}"
  elif [ "${TYPE}" = "task" ]; then
    printf "\n${MESSAGE_STEP}\e[1m\e[37m${TITLE}\e[0m${MESSAGE}"
  fi
}
function step () {
  printf "\n${1}${TIMELINE_STEP}"
}
function open_input () {
  printf "\e[33m\e[1m\e[?25h"
}
function close_input () {
  printf "\033[1A\e[0m\e[?25l"
}
function spinner () {
  local GROUP_PID=$!
  local DELAY=0.05
  local i=0
  SP[0]="⠇"
  SP[1]="⡆"
  SP[2]="⣄"
  SP[3]="⣠"
  SP[4]="⢰"
  SP[5]="⠸"
  SP[6]="⠙"
  SP[7]="⠋"
  printf "\e[30m\e[1m\r${TIMELINE_L_MARGIN}\b[ ]\e[0m\b"
  if [ "${KERNEL}" = "Darwin" ]; then
    # "^\s*(^|\W)${GROUP_PID}($|\W)"
    while [ $(ps ax | grep -w -E "^\s*${GROUP_PID}" | wc -l) != "0" ]; do
      printf "\b\e[33m\e[1m${SP[i++]}\e[0m"
      if [ "${i}" = "${#SP[@]}" ]; then i=0; fi
    done
  else
    while [ -d "/proc/${GROUP_PID}" ]; do
      printf "\b\e[33m\e[1m${SP[i++]}\e[0m"
      if [ "${i}" = "${#SP[@]}" ]; then i=0; fi
      sleep ${DELAY}
    done
  fi
  clear_spinner ok
}
function clear_spinner () {
  local SYMBOL=$1
  if [ "${SYMBOL}" = "ok" ]; then
    printf "\b${CHECK_SYMBOL}\b\033[1C"
  elif [ "${SYMBOL}" = "fail" ]; then
    printf "\b${CANCEL_SYMBOL}\b\033[1C"
  fi
}
function catch_error () {
  local LAST_COMMAND_EXIT_STATUS=$1
  local MESSAGE=$2
  if [ "${LAST_COMMAND_EXIT_STATUS}" -ne "0" ]; then
    # Si se sube la velocidad de la animación del spiner, se corre peligro que
    # se vuelva a imprimir el espiner antes de llegar al comando 'terminate_script'
    clear_spinner fail
    step
    display_message error "${MESSAGE}"
    terminate_script
    exit 1
  fi
}
function display_help () {
  printf "
                                  \e[1m██▄███▄ ██▌ ▐██ ██▌ ▐██\e[0m
                                  \e[1m██▌ ▐██ ██▌ ▐██ ██▌ ▐██\e[0m
                                  \e[1m██▌ ▐███▀███▀██ ▀███▀██\e[0m
                                   NUU Group Engineering
 \e[34m▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄\e[0m\b
 \e[1m\e[44m  S1 Project Setup Script                       ${VERSION}  \e[0m\b
 \e[34m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\e[0m\b
 Tool for creation and initial configuration for projects
 that are built with the following technologies stack:

 • Phoenix Framework
 • Webpack Module Bundler
 • React Library
 • GraphQL Query Language

 \e[1mLanguage: \e[0m
   English

 \e[1mUsage:\e[0m\b
   ${0} [\e[33mapplication_name \e[0m\b]

 \e[1mOptions:\e[0m\b
   -h --help
      --path [\e[33mruta_destino \e[0m\b]
      --module [\e[33mmódulo_base \e[0m\b]
      --database [\e[36m\e[1mpostgres\e[35m|\e[36mmysql\e[35m|\e[36mmssql \e[0m\b]\n"
}
function display_header () {
  printf "
${TIMELINE_STEP} \e[1mProject technologies stack:\e[0m  \e[30m\e[1m│\e[0m  \e[1mRequired installed software:\e[0m
${TIMELINE_STEP}                              \e[30m\e[1m│\e[0m 
${TIMELINE_STEP} • Phoenix Framework          \e[30m\e[1m│\e[0m  Phoenix      \e[30m\e[1m[\e[0m${PHX_S}\e[30m\e[1m]\e[0m ${PHX_V}
${TIMELINE_STEP} • Webpack Module Bundler     \e[30m\e[1m│\e[0m   └ Elixir    \e[30m\e[1m[\e[0m${EX_S}\e[30m\e[1m]\e[0m ${EX_V}
${TIMELINE_STEP} • React Library              \e[30m\e[1m│\e[0m      └ Erlang \e[30m\e[1m[\e[0m${ERL_S}\e[30m\e[1m]\e[0m ${ERL_V}
${TIMELINE_STEP} • GraphQL Query Language     \e[30m\e[1m│\e[0m  NPM          \e[30m\e[1m[\e[0m${NPM_S}\e[30m\e[1m]\e[0m ${NPM_V}
${TIMELINE_STEP}                              \e[30m\e[1m│\e[0m   └ Node.js   \e[30m\e[1m[\e[0m${NODE_S}\e[30m\e[1m]\e[0m ${NODE_V}"
}
function terminate_script () {
  printf "\e[0m\e[?25h\n"
  kill -s TERM "${SCRIPT_PID}"
  exit 1
}
# Asignacion de opciones y argumentos a las variables ------------------------
while [ "$#" != "0" ]
do
  if [ "${1:0:2}" = "--" ]; then
    if [ "${1}" = "--help" ]; then 
      display_help
      exit 0
    elif [ "${1}" = "--path" ]; then
      if [ "${2:0:2}" = "--" ] || [ "${2:0:1}" = "-" ] || [ "${2}" = "" ]; then
        display_message arg_error "The \e[1m${1}\e[0m option require 1 argument"
        exit 1
      fi
      shift
      TARGET_PATH=${1}
    elif [ "${1}" = "--module" ]; then
      if [ "${2:0:2}" = "--" ] || [ "${2:0:1}" = "-" ] || [ "${2}" = "" ]; then
        display_message arg_error "The \e[1m${1}\e[0m option require 1 argument"
        exit 1
      fi
      shift
      MODULE="$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"
    elif [ "${1}" = "--database" ]; then
      if [ "${2}" = "postgres" ] || [ "${2}" = "mysql" ] || [ "${2}" = "mssql" ]; then
        shift
        DATABASE=${1}
      elif [ "${2}" = "" ]; then
        display_message arg_error "The \e[1m${1}\e[0m option require 1 argument"
        exit 1
      else
        display_message arg_error "Database not supported" "(Run the script with option \e[1m--help\e[0m for more information)"
        exit 1
      fi
    else
      display_message arg_error "The \e[1m${1}\e[0m option does not exists"
      exit 1
    fi
  elif [ "${1:0:1}" = "-" ]; then
    if [ "${1}" = "-h" ]; then 
      display_help
      exit 0
    else
      display_message arg_error "The \e[1m${1}\e[0m option does not exists"
      exit 1
    fi
  else
    if [ "${ARGS_COUNT}" = "0" ]; then 
      PROJECT_NAME=$(awk '{print tolower($0)}' <<< "$1")
    fi
    let ARGS_COUNT++
  fi
  shift
done
# Argumentos default ----------------------------------------------------------
if [ -z "${MODULE}" ]; then
  IFS='_'; a=(${PROJECT_NAME}); unset IFS;
  for VAR in "${a[@]}"
  do
    MODULE=${MODULE}"$(awk '{print toupper(substr($0,1,1)) tolower(substr($0,2)) }' <<< ${VAR})"
  done
fi
if [ -z "${TARGET_PATH}" ]; then
  TARGET_PATH="./" 
elif [ "${TARGET_PATH: -1}" != "/" ] && [ "${TARGET_PATH: -1}" != "\\" ]; then
  TARGET_PATH="${TARGET_PATH}/"
fi
if [ -z "${DATABASE}" ]; then
  DATABASE="postgres"
fi
# Validaciones de argumentos -------------------------------------------------
if [ -z "${PROJECT_NAME}" ]; then
  display_message arg_error "Its needed to specify the name of the project" "(Run the script with option \e[1m--help\e[0m for more information)"
  exit 1
fi
if [ ! -d "${TARGET_PATH}" ]; then
  display_message arg_error "The path where the project will be created does not exist"
  exit 1
fi
cd ${TARGET_PATH}
if [ -d "${PROJECT_NAME}" ]; then
  display_message arg_error "The directory \"${TARGET_PATH}${PROJECT_NAME}\" already exists:" "Select another project name for installation"
  exit 1
fi
# Funciones de proceso -------------------------------------------------------
function validations () {
  # Se checa que las tecnologías necesarias estén todas instaladas
  if [ "${PHX_V}" = "" ] || [ "${NPM_V}" = "" ] || [ "${EX_V}" = "" ] || [ "${NODE_V}" = "" ]; then
    display_message error "One of the technologies needed to create the project is not installed correctly"
    terminate_script
    exit 1
  fi
}
function task1 () {
  display_message task "Creating Phoenix project "
  {
  #--- 1 ---
    echo y | mix phx.new "${PROJECT_NAME}" --module "${MODULE}" --database "${DATABASE}" &>/dev/null
    catch_error $? "The Phoenix project could not be created correctly"
  } & spinner
}
function task2 () {
  display_message task "Uninstalling Brunch and relative dependencies "
  {
  #--- 2 ---
    cd "${PROJECT_NAME}/assets" &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 3 ---
    if [ "${KERNEL}" = "Darwin" ]; then 
      sed -i "" $'s/{},/{},\\\n  "description": " ",/g' package.json &>/dev/null
    else 
      sed -i $'s/{},/{},\\\n  "description": " ",/g' package.json &>/dev/null
    fi
    catch_error $? "Unable to add description to \"package.json\" file"
  #--- 4 ---
    npm uninstall --save-dev brunch babel-brunch clean-css-brunch uglify-js-brunch &>/dev/null
    catch_error $? "The uninstallation via NPM could not be executed correctly"
  #--- 5 ---
    rm brunch-config.js &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets/brunch-config.js\" file could not be deleted"
  } & spinner
}
function task3 () {
  display_message task "Installing Webpack, React, GraphQL and other dependencies "
  {
  #--- 6 ---
    cd "${PROJECT_NAME}/assets" &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 7 ---
    npm install --save-dev webpack webpack-cli copy-webpack-plugin uglifyjs-webpack-plugin graphql react react-dom react-router-dom prop-types @babel/core @babel/cli @babel/preset-env @babel/preset-react @babel/plugin-proposal-class-properties babel-loader css-loader url-loader file-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin &>/dev/null
    catch_error $? "The installation via NPM could not be executed correctly"
  } & spinner
}
function task4 () {
  display_message task "Configuring dependencies and project file structure "
  {
  #--- 8 ---
    cd "${PROJECT_NAME}/assets" &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 9 ---
    touch webpack.config.js &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets/webpack.config.js\" file could not be created"
  #--- 10 ---
    cat &>/dev/null <<EOM >"webpack.config.js"
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
EOM
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/webpack.config.js\" file"
  #--- 11 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" $'s/"deploy": "brunch build --production"/"deploy": "webpack --mode production"/g' package.json &>/dev/null
    else
      sed -i $'s/"deploy": "brunch build --production"/"deploy": "webpack --mode production"/g' package.json &>/dev/null
    fi
    catch_error $? "Unable to replace script \"deploy\" in \"${PROJECT_NAME}/assets/package.json\" file"
  #--- 12 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" $'s/"watch": "brunch watch --stdin"/"start": "webpack --mode development --watch-stdin --color"/g' package.json &>/dev/null
    else
      sed -i $'s/"watch": "brunch watch --stdin"/"start": "webpack --mode development --watch-stdin --color"/g' package.json &>/dev/null
    fi
    catch_error $? "Unable to replace script \"watch\" in \"${PROJECT_NAME}/assets/package.json\" file"
  #--- 13 ---
    cd ../config &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/config\" directory could not be accessed"
  #--- 14 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" $'s|watchers: \[node: \["node_modules/brunch/bin/brunch", "watch", "--stdin",|watchers: \[node: \["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color",|g' dev.exs &>/dev/null
    else
      sed -i $'s|watchers: \[node: \["node_modules/brunch/bin/brunch", "watch", "--stdin",|watchers: \[node: \["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color",|g' dev.exs &>/dev/null
    fi
    catch_error $? "Unable to replace script \"watchers\" in \"${PROJECT_NAME}/config/dev.exs\" file"
  #--- 15 ---
    cd ../assets &>/dev/null
    catch_error $? "The \"$PROJECT_NAME/assets\" directory could not be accessed"
  #--- 16 ---
    touch .babelrc &>/dev/null
    catch_error $? "Unable to create \"${PROJECT_NAME}/assets/.babelrc\" file"
  #--- 17 ---
    cat &>/dev/null <<EOM >".babelrc"
{
  "presets": [
    ["@babel/preset-env", {"modules" : false}],
    "@babel/preset-react"
  ],
  "plugins": [
    "@babel/plugin-proposal-class-properties"
  ]
}
EOM
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/.babelrc\" file"
  #--- 18 ---
    cd js &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}/assets/js\" directory could not be accessed"
  #--- 19 ---
    touch index.js
    catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/index.js\" file"
  #--- 20 ---
    cat &>/dev/null <<EOM >"index.js"
// Dependencies
import React, { Component } from 'react';
import ReactDOM from 'react-dom';

class App extends Component {
  render() {
    return (
      <div>Configuration was successful!</div>
    );
  }
}

ReactDOM.render(
  <App />,
  document.getElementById('root')
);
EOM
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/js/index.js\" file"
    #--- 21 ---
      mkdir components &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/components\" directory"
    #--- 22 ---
      mkdir pages &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/pages\" directory"
    #--- 23 ---
      mkdir data &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/data\" directory"
    #--- 24 ---
      if [ "$KERNEL" = "Darwin" ]; then
        sed -i "" $'/"phoenix_html"/a \
        import css from "..\/css\/app.css"\\\nimport { index } from ".\/index"\\\n' app.js &>/dev/null
      else
        sed -i $'/"phoenix_html"/a \import css from "..\/css\/app.css"\\\nimport { index } from ".\/index"\\\n' app.js &>/dev/null
      fi
      catch_error $? "Could not add the imports in \"${PROJECT_NAME}/assets/js/app.js\" file"
    #--- 25 ---
      cd ../../lib/"${PROJECT_NAME}"_web/templates/layout &>/dev/null
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout\" directory could not be accessed"
    #--- 26 ---
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" $'/<body>/,/<\/body>/d' app.html.eex &>/dev/null
      else
        sed -i $'/<body>/,/<\/body>/d' app.html.eex &>/dev/null
      fi
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\" file"
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" $'/<\/head>/a \
        \\\n  <body>\\\n    <main role="main">\\\n      <%= render @view_module, @view_template, assigns %>\\\n    <\/main>\\\n    <script src="<%= static_path(@conn, "\/js\/app.js") %>"><\/script>\\\n  <\/body>' app.html.eex &>/dev/null
      else
        sed -i $'/<\/head>/a \
        \\\n  <body>\\\n    <main role="main">\\\n      <%= render @view_module, @view_template, assigns %>\\\n    <\/main>\\\n    <script src="<%= static_path(@conn, "\/js\/app.js") %>"><\/script>\\\n  <\/body>' app.html.eex &>/dev/null
      fi
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\" file"
    #--- 27 ---
      cd ../page &>/dev/null
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page\" directory could not be accessed"
    #--- 28 ---
      echo "<div id=\"root\"></div>" > "index.html.eex" # &>/dev/null
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page/index.html.eex\" file"
    #--- 29 ---
      cd ../.. &>/dev/null
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web\" directory could not be accessed"
    #--- 30 ---
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" $'/^\(end\)/i \
        \\\n  if Mix.env == :dev do\\\n    forward \"/graphiql\", Absinthe.Plug.GraphiQL,\\\n      schema: '"${MODULE}"$'.Graphql.Schema,\\\n      interface: :advanced,\\\n      context: %{pubsub: '"${MODULE}"$'.Endpoint}\\\n  end\\\n' router.ex &>/dev/null
      else
        sed -i $'/^\(end\)/i \
        \\\n  if Mix.env == :dev do\\\n    forward \"/graphiql\", Absinthe.Plug.GraphiQL,\\\n      schema: '"${MODULE}"$'.Graphql.Schema,\\\n      interface: :advanced,\\\n      context: %{pubsub: '"${MODULE}"$'.Endpoint}\\\n  end\\\n' router.ex &>/dev/null
      fi
      catch_error $? "Could not add the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/router.ex\" file"
    #--- 31 ---
      cd ../"${PROJECT_NAME}" &>/dev/null
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}\" directory could not be accessed"
    #--- 32 ---
      mkdir graphql &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\" directory"
    #--- 33 ---
      cd graphql &>/dev/null
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\" directory could not be accessed"
    #--- 34 ---
      touch queries.ex &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/queries.ex\" file"
    #--- 35 ---
      touch mutations.ex &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/mutations.ex\" file"
    #--- 36 ---
      touch subscriptions.ex &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/subscriptions.ex\" file"
    #--- 37 ---
      touch schema.ex &>/dev/null
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/schema.ex\" file"
    #--- 38 ---
      cat &>/dev/null <<EOM >"queries.ex"
defmodule $MODULE.Graphql.Queries do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :queries do
  end
end
EOM
      catch_error $? "Unable to add content to \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/queries.ex\" file"
    #--- 39 ---
      cat &>/dev/null <<EOM >"mutations.ex"
defmodule $MODULE.Graphql.Mutations do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :mutations do
  end
end
EOM
      catch_error $? "Unable to add content to \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/mutations.ex\" file"
    #--- 40 ---
      cat &>/dev/null <<EOM >"subscriptions.ex"
defmodule $MODULE.Graphql.Subscriptions do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :subscriptions do
  end
end
EOM
      catch_error $? "Unable to add content to \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/subscriptions.ex\" file"
    #--- 41 ---
      cat &>/dev/null <<EOM >"schema.ex"
defmodule $MODULE.Graphql.Schema do
  @moduledoc false

  use Absinthe.Schema

  import_types $MODULE.Graphql.Queries
  import_types $MODULE.Graphql.Mutations
  import_types $MODULE.Graphql.Subscriptions
  import_types Absinthe.Plug.Types
  import_types Absinthe.Type.Custom

  query [], do: import_fields :queries
  mutation [], do: import_fields :mutations
  subscription [], do: import_fields :subscriptions
end
EOM
      catch_error $? "Unable to add content to \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/schema.ex\" file"
  } & spinner
}
function task5 () {
  display_message task "Compiling dependencies for Phoenix "
  {
  #--- 42 ---
    cd "${PROJECT_NAME}" &>/dev/null
    catch_error $? "The \"${PROJECT_NAME}\" directory could not be accessed"
  #--- 43 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -E -i "" $'s/{:cowboy, "~> [0-9]+\.[0-9]+"}/{:plug_cowboy, "~> 1.0"},\\\n      {:absinthe, "~> 1.4.13"},\\\n      {:absinthe_ecto, "~> 0.1.3"},\\\n      {:absinthe_plug, "~> 1.4.6"},\\\n      {:absinthe_phoenix, "~> 1.4.3"}/' mix.exs &>/dev/null
    else
      sed -i $'s/{:cowboy, "~> [0-9][0-9]*\.[0-9][0-9]*"}/{:plug_cowboy, "~> 1.0"},\\\n      {:absinthe, "~> 1.4.13"},\\\n      {:absinthe_ecto, "~> 0.1.3"},\\\n      {:absinthe_plug, "~> 1.4.6"},\\\n      {:absinthe_phoenix, "~> 1.4.3"}/' mix.exs &>/dev/null
    fi
    catch_error $? "The dependencies could not be modified in \"${PROJECT_NAME}/mix.exs\" file"
  #--- 44 ---
    mix deps.get &>/dev/null
    catch_error $? "Unable to download dependencies for Phoenix"
  #--- 45 ---
    mix deps.compile &>/dev/null
    catch_error $? "Unable to compile dependencies for Phoenix"
  } & spinner
}

# Procesamiento ================================================================
# Ocultar cursor
printf "\e[?25l"
# Versions
{
  # Se checa que esté instalado Phoenix
  PHX_V=$(mix phx.new --version 2>/dev/null)
  if [ "$?" -eq "0" ]; then
    IFS=' '; a=($PHX_V); unset IFS;
    PHX_V="\e[32m${a[1]:1}\e[0m"
    PHX_S=${CHECK_SYMBOL}
  else
    PHX_V=""
    PHX_S=${CANCEL_SYMBOL}
  fi
  # Se checa que esté instalado NPM
  NPM_V=$(npm -v 2>/dev/null)
  if [ "$?" -eq "0" ]; then
    NPM_V="\e[32m${NPM_V}\e[0m"
    NPM_S=${CHECK_SYMBOL}
  else
    NPM_V=""
    NPM_S=${CANCEL_SYMBOL}
  fi
  # Se checa que esté instalado Elixir
  EX_INFO=$(elixir --version 2>/dev/null)
  if [ "$?" -eq "0" ]; then
    if [ "${KERNEL}" = "Darwin" ]; then
      EX_V=($(sed -E -n 's|(Elixir [0-9]+(\.[0-9]+)*)(.*)|\1|p' <<< "${EX_INFO}"))
      EX_OTP_V=($(sed -E -n 's|(.*)(with OTP [0-9]+(\.[0-9]+)*)(.*)|\2|p' <<< "${EX_INFO}"))
      ERL_V=($(sed -E -n 's|(Erlang/OTP [0-9]+(\.[0-9]+)*)(.*)|\1|p' <<< "${EX_INFO}"))
    else
      EX_V=($(sed -r -n 's|(Elixir [0-9]+(\.[0-9]+)*)(.*)|\1|p' <<< "${EX_INFO}"))
      EX_OTP_V=($(sed -r -n 's|(.*)(with OTP [0-9]+(\.[0-9]+)*)(.*)|\2|p' <<< "${EX_INFO}"))
      ERL_V=($(sed -r -n 's|(Erlang/OTP [0-9]+(\.[0-9]+)*)(.*)|\1|p' <<< "${EX_INFO}"))
    fi
    if [ "${EX_OTP_V}" = "" ]; then
      EX_V="\e[32m${EX_V[1]}\e[0m"
    else
      EX_V="\e[32m${EX_V[1]} (OTP ${EX_OTP_V[2]})\e[0m"
    fi
    EX_S=${CHECK_SYMBOL}
    # Medio chaco porque necesita su propio comando de version
    ERL_V="\e[32mOTP ${ERL_V[1]}\e[0m"
    ERL_S=${CHECK_SYMBOL}
  else
    EX_V=""
    EX_S=${CANCEL_SYMBOL}
    # Medio chaco porque necesita su propio comando de version
    ERL_V=""
    ERL_S=${CANCEL_SYMBOL}
  fi
  # Se checa que esté instalado Node.js
  NODE_V=$(node -v 2>/dev/null)
  if [ "$?" -eq "0" ]; then
    NODE_V="\e[32m${NODE_V:1}\e[0m"
    NODE_S=${CHECK_SYMBOL}
  else
    NODE_V=""
    NODE_S=${CANCEL_SYMBOL}
  fi
}
display_header
step
validations
# ------------------------------------------------------------------------------

task1
task2
task3
task4
task5

# ------------------------------------------------------------------------------
step
display_message green "The project has been created and configured correctly!"
printf "

 Go into your application by running:
 
   \e[1m$ cd ${TARGET_PATH}${PROJECT_NAME}\e[0m
 
 Then configure your database in config/dev.exs and run:
 
   \e[1m$ mix ecto.create\e[0m
 
 Start your Phoenix app with:
 
   \e[1m$ mix phx.server\e[0m
 
 You can also run your app inside IEx (Interactive Elixir) as:
 
   \e[1m$ iex -S mix phx.server\e[0m
"
# Mostrar cursor
printf "\e[?25h"
exit 0
# ==============================================================================


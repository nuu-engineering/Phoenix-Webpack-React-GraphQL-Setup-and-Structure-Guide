# -*- ENCODING: UTF-8 -*-
#!/bin/bash
VERSION="v1.0"
trap terminate_script SIGINT
# Remember: sed -i "s|\\r\\n|\\n|g" nuu.project-s1.sh

# Tiene problemas de compatibilidad con MAC en los subprocesos & con spinner

# Variables ====================================================================
PROJECT_NAME=""
MODULE=""
TARGET_PATH=""
# Variables de control -------------------------------------------------------
SCRIPT_PID=$$
KERNEL=$(uname -s)
VERBOSE="false"
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
    local TITLE="Fail: "
  elif [ "${TYPE}" = "green" ]; then
    local MESSAGE_STEP="\e[32m${TIMELINE_L_MARGIN}${TIMELINE_END_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
    local TITLE="Done: "
  elif [ "${TYPE}" = "warning" ]; then
    local MESSAGE_STEP="\e[33m${TIMELINE_L_MARGIN}${TIMELINE_SYMBOL}${TIMELINE_R_MARGIN}\e[0m"
    local TITLE="Warning: "
  elif [ "${TYPE}" = "blue" ]; then
    local MESSAGE_STEP="\e[0m${TIMELINE_STEP}"
    local TITLE="Input: "
  elif [ "${TYPE}" = "task" ]; then
    local MESSAGE_STEP="\e[0m${TIMELINE_STEP}"
    let TASK_COUNT++
    local TITLE="Task ${TASK_COUNT}: "
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
  local SPINNER_PID=$!
  local i=0
  SP[0]="⠋"
  SP[1]="⠇"
  SP[2]="⡆"
  SP[3]="⣄"
  SP[4]="⣠"
  SP[5]="⢰"
  SP[6]="⠸"
  SP[7]="⠙"
  printf "\e[30m\e[1m[ ]\e[0m\b"
  while [ -d "/proc/${SPINNER_PID}" ]; do
    if [ true ]; then
      printf "\b\e[33m\e[1m${SP[i++]}\e[0m"
      if [ "${i}" = "${#SP[@]}" ]; then i=0; fi
      sleep 0.05
    fi
  done
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
    # Si se suve la velocidad de la animación del spiner, se corre peligro que
    # se vuelva a imprimir el espiner antes de llegar al comando 'terminate_script'
    clear_spinner fail
    step
    display_message error "${MESSAGE}"
    terminate_script
    exit 1
  fi
}
function display_help () {
  printf " \e[34m▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄\e[0m\b
 \e[1m\e[44m  NUU Group: S1 Project Setup Script                    \e[0m\b
 \e[34m▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀\e[0m\b
 Tool for creation and initial configuration for projects
 that are built with the following technologies stack:

 \e[1m•\e[0m Phoenix Framework
 \e[1m•\e[0m Webpack Module Bundler
 \e[1m•\e[0m React Library
 \e[1m•\e[0m GraphQL Query Language

 \e[1mVersion: \e[0m\b ${VERSION}

 \e[1mUsage:\e[0m\b
   ${0} [\e[33mapplication_name \e[0m\b]

 \e[1mOptions:\e[0m\b
   -h --help
   -p --path [\e[33mtarget_path \e[0m\b]
   -m --module [\e[33mbase_module \e[0m\b]\n"
}
function display_header () {
  printf "
${TIMELINE_STEP}                          │  \e[1mProject technologies stack:\e[0m  │  \e[1mRequired installed software:\e[0m
${TIMELINE_STEP} \e[1m██▄███▄ ██▌ ▐██ ██▌ ▐██\e[0m  │                               │ 
${TIMELINE_STEP} \e[1m██▌ ▐██ ██▌ ▐██ ██▌ ▐██\e[0m  │  • Phoenix Framework          │  Phoenix      \e[30m\e[1m[\e[0m${PHX_S}\e[30m\e[1m]\e[0m ${PHX_V}
${TIMELINE_STEP} \e[1m██▌ ▐███▀███▀██ ▀███▀██\e[0m  │  • Webpack Module Bundler     │   └ Elixir    \e[30m\e[1m[\e[0m${EX_S}\e[30m\e[1m]\e[0m ${EX_V}
${TIMELINE_STEP}  NUU Group Engineering   │  • React Library              │      └ Erlang \e[30m\e[1m[\e[0m${ERL_S}\e[30m\e[1m]\e[0m ${ERL_V}
${TIMELINE_STEP}                          │  • GraphQL Query Language     │  NPM          \e[30m\e[1m[\e[0m${NPM_S}\e[30m\e[1m]\e[0m ${NPM_V}
${TIMELINE_STEP}                          │                               │   └ Node.js   \e[30m\e[1m[\e[0m${NODE_S}\e[30m\e[1m]\e[0m ${NODE_V}"
}
function terminate_script () {
  printf "\e[?25h\n"
  kill -s TERM "${SCRIPT_PID}"
  exit 1
}
# Asignacion de opciones y argumentos a las variables ------------------------
# Opciones
TEMP=$(getopt -o p:m:h --long path:,module:,help -n -- "$@")
eval set -- "$TEMP"
while true ; do
    case "$1" in
        -h|--help) display_help; exit 0 ;;
        -p|--path)
            case "$2" in
                "") shift 2 ;;
                *) TARGET_PATH=$2 ; shift 2 ;;
            esac ;;
        -m|--module)
            case "$2" in
                "") shift 2 ;;
                *) MODULE="$(tr '[:lower:]' '[:upper:]' <<< ${2:0:1})${2:1}" ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done
# Argumentos
for VAR in "$@"
do
  if [ "${ARGS_COUNT}" = "0" ]; then 
    PROJECT_NAME=$(awk '{print tolower($0)}' <<< "$1")
  fi
  let ARGS_COUNT++
  shift
done 
# Argumentos default
if [ -z "${MODULE}" ]; then
  IFS='_'; a=(${PROJECT_NAME}); unset IFS;
  for VAR in "${a[@]}"
  do
    MODULE=${MODULE}"$(awk '{print toupper(substr($0,1,1)) tolower(substr($0,2)) }' <<< ${VAR})"
  done
fi
if [ -z "${TARGET_PATH}" ]; then
  TARGET_PATH="./" 
fi
# Funciones de proceso -------------------------------------------------------
function validations () {
  # Se checa que las tecnologías necesarias estén todas instaladas
  if [ "${PHX_V}" = "" ] || [ "${NPM_V}" = "" ] || [ "${EX_V}" = "" ] || [ "${NODE_V}" = "" ]; then
    # <lang> display_message error "Una de las tecnologías necesarias para crear el proyecto no está instalada correctamente"
    display_message error "One of the technologies needed to create the project is not installed correctly"
    terminate_script
    exit 1
  fi
  # Se checa que se haya introducido el primer argumento que es el título
  if [ -z "${PROJECT_NAME}" ]; then
    # <lang> display_message error "Falta especificar el nombre del proyecto:" "Ejecuta el script con la opción \e[1m--help\e[0m para más información"
    display_message error "Its needed to specify the name of the project:" "Run the script with option \e[1m--help\e[0m for more information"
    terminate_script
    exit 1
  fi
  # Se checa que la ruta dada exista
  if [ ! -d "${TARGET_PATH}" ]; then
    # <lang> display_message error "La ruta donde se creará el proyecto no existe"
    display_message error "The path where the project will be created does not exist"
    terminate_script
    exit 1
  fi
  # Se checa si ya existe un directorio con el nombre de proyecto
  cd ${TARGET_PATH}
  if [ -d "${PROJECT_NAME}" ]; then
    # <lang> display_message error "Ya existe un directorio \"${PROJECT_NAME}\":" "Selecciona otro directorio para la instalación"
    display_message error "A directory \"${PROJECT_NAME}\" already exists:" "Select another directory for installation"
    terminate_script
    exit 1
  fi
}
function task1 () {
  # <lang> display_message task "Creando proyecto Phoenix "
  display_message task "Creating Phoenix project "
  {
  #--- 1 ---
    echo y | mix phx.new "${TARGET_PATH}/${PROJECT_NAME}" --module ${MODULE} --app ${PROJECT_NAME} &>/dev/null
    # <lang> catch_error $? "No se pudo crear el proyecto de Phoenix correctamente"
    catch_error $? "The Phoenix project could not be created correctly"
  } & spinner
}
function task2 () {
  # <lang> display_message task "Desinstalando Brunch y dependencias relativas "
  display_message task "Uninstalling Brunch and relative dependencies "
  {
  #--- 2 ---
    cd "${TARGET_PATH}/${PROJECT_NAME}/assets" &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/assets\""
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 3 ---
    if [ "${KERNEL}" = "Darwin" ]; then 
      sed -i "" $'s/{},/{},\\\n  "description": " ",/g' package.json &>/dev/null
    else 
      sed -i 's/{},/{},\n  "description": " ",/g' package.json &>/dev/null
    fi
    # <lang> catch_error $? "No se pudo agregar descripción al archivo \"package.json\""
    catch_error $? "Unable to add description to \"package.json\" file"
  #--- 4 ---
    npm uninstall --save-dev brunch babel-brunch clean-css-brunch uglify-js-brunch &>/dev/null
    # <lang> catch_error $? "No se pudo ejecutar la desinstalación vía NPM correctamente"
    catch_error $? "The uninstallation via NPM could not be executed correctly"
  #--- 5 ---
    rm brunch-config.js &>/dev/null
    # <lang> catch_error $? "No se pudo eliminar el archivo \"${PROJECT_NAME}/assets/brunch-config.js\""
    catch_error $? "The \"${PROJECT_NAME}/assets/brunch-config.js\" file could not be deleted"
  } & spinner
}
function task3 () {
  # <lang> display_message task "Instalando Webpack, React, GraphQL y otras dependencias "
  display_message task "Installing Webpack, React, GraphQL and other dependencies "
  {
  #--- 6 ---
    cd "${TARGET_PATH}/${PROJECT_NAME}/assets" &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/assets\""
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 7 ---
    npm install --save-dev webpack webpack-cli copy-webpack-plugin uglifyjs-webpack-plugin graphql react react-dom react-router-dom prop-types @babel/core @babel/cli @babel/preset-env @babel/preset-react @babel/plugin-proposal-class-properties babel-loader css-loader url-loader file-loader mini-css-extract-plugin optimize-css-assets-webpack-plugin &>/dev/null
    # <lang> catch_error $? "No se pudo ejecutar la instalación vía NPM correctamente"
    catch_error $? "The installation via NPM could not be executed correctly"
  } & spinner
}
function task4 () {
  # <lang> display_message task "Configurando dependencias y estructura de archivos del proyecto "
  display_message task "Configuring dependencies and project file structure "
  {
  #--- 8 ---
    cd "${TARGET_PATH}/${PROJECT_NAME}/assets" &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/assets\""
    catch_error $? "The \"${PROJECT_NAME}/assets\" directory could not be accessed"
  #--- 9 ---
    touch webpack.config.js &>/dev/null
    # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/assets/webpack.config.js\""
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
    # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/assets/webpack.config.js\""
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/webpack.config.js\" file"
  #--- 11 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" 's/"deploy": "brunch build --production"/"deploy": "webpack --mode production"/g' package.json &>/dev/null
    else
      sed -i 's/"deploy": "brunch build --production"/"deploy": "webpack --mode production"/g' package.json &>/dev/null
    fi
    # <lang> catch_error $? "No se pudo reemplazar el script \"deploy\" en \"${PROJECT_NAME}/assets/package.json\""
    catch_error $? "Unable to replace script \"deploy\" in \"${PROJECT_NAME}/assets/package.json\" file"
  #--- 12 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" 's/"watch": "brunch watch --stdin"/"start": "webpack --mode development --watch-stdin --color"/g' package.json &>/dev/null
    else
      sed -i 's/"watch": "brunch watch --stdin"/"start": "webpack --mode development --watch-stdin --color"/g' package.json &>/dev/null
    fi
    # <lang> catch_error $? "No se pudo reemplazar el script \"watch\" en \"${PROJECT_NAME}/assets/package.json\""
    catch_error $? "Unable to replace script \"watch\" in \"${PROJECT_NAME}/assets/package.json\" file"
  #--- 13 ---
    cd ../config &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/config\""
    catch_error $? "The \"${PROJECT_NAME}/config\" directory could not be accessed"
  #--- 14 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -i "" 's|watchers: \[node: \["node_modules/brunch/bin/brunch", "watch", "--stdin",|watchers: \[node: \["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color",|g' dev.exs &>/dev/null
    else
      sed -i 's|watchers: \[node: \["node_modules/brunch/bin/brunch", "watch", "--stdin",|watchers: \[node: \["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin", "--color",|g' dev.exs &>/dev/null
    fi
    # <lang> catch_error $? "No se pudo reemplazar el script \"watchers\" en \"${PROJECT_NAME}/config/dev.exs\""
    catch_error $? "Unable to replace script \"watchers\" in \"${PROJECT_NAME}/config/dev.exs\" file"
  #--- 15 ---
    cd ../assets &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"$PROJECT_NAME/assets\""
    catch_error $? "The \"$PROJECT_NAME/assets\" directory could not be accessed"
  #--- 16 ---
    touch .babelrc &>/dev/null
    # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/assets/.babelrc\""
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
    # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/assets/.babelrc\""
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/.babelrc\" file"
  #--- 18 ---
    cd js &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/assets/js\""
    catch_error $? "The \"${PROJECT_NAME}/assets/js\" directory could not be accessed"
  #--- 19 ---
    touch index.js
    # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/assets/js/index.js\""
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
    # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/assets/js/index.js\""
    catch_error $? "Unable to add content to \"${PROJECT_NAME}/assets/js/index.js\" file"
    #--- 21 ---
      mkdir components &>/dev/null
      # <lang> catch_error $? "No se pudo crear el directorio \"${PROJECT_NAME}/assets/js/components\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/components\" directory"
    #--- 22 ---
      mkdir pages &>/dev/null
      # <lang> catch_error $? "No se pudo crear el directorio \"${PROJECT_NAME}/assets/js/pages\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/pages\" directory"
    #--- 23 ---
      mkdir data &>/dev/null
      # <lang> catch_error $? "No se pudo crear el directorio \"${PROJECT_NAME}/assets/js/data\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/assets/js/data\" directory"
    #--- 24 ---
      if [ "$KERNEL" = "Darwin" ]; then
        sed -i "" $'/"phoenix_html"/a \import css from "..\/css\/app.css"\\\nimport { index } from ".\/index"\\\n' app.js &>/dev/null
      else
        sed -i $'/"phoenix_html"/a \import css from "..\/css\/app.css"\\\nimport { index } from ".\/index"\\\n' app.js &>/dev/null
      fi
      # <lang> catch_error $? "No se pudieron agregar los imports en \"${PROJECT_NAME}/assets/js/app.js\""
      catch_error $? "Could not add the imports in \"${PROJECT_NAME}/assets/js/app.js\" file"
    #--- 25 ---
      cd ../../lib/"${PROJECT_NAME}"_web/templates/layout &>/dev/null
      # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout\""
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout\" directory could not be accessed"
    #--- 26 ---
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" '/<body>/,/<\/body>/d' app.html.eex &>/dev/null
      else
        sed -i '/<body>/,/<\/body>/d' app.html.eex &>/dev/null
      fi
      # <lang> catch_error $? "No se pudo reemplazar el código en \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\""
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\" file"
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" $'/<\/head>/a \
        \\\n  <body>\\\n    <main role="main">\\\n      <%= render @view_module, @view_template, assigns %>\\\n    <\/main>\\\n    <script src="<%= static_path(@conn, "\/js\/app.js") %>"><\/script>\\\n  <\/body>' app.html.eex &>/dev/null
      else
        sed -i $'/<\/head>/a \
        \\\n  <body>\\\n    <main role="main">\\\n      <%= render @view_module, @view_template, assigns %>\\\n    <\/main>\\\n    <script src="<%= static_path(@conn, "\/js\/app.js") %>"><\/script>\\\n  <\/body>' app.html.eex &>/dev/null
      fi
      # <lang> catch_error $? "No se pudo reemplazar el código en \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\""
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/layout/app.html.eex\" file"
    #--- 27 ---
      cd ../page &>/dev/null
      # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page\""
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page\" directory could not be accessed"
    #--- 28 ---
      echo "<div id=\"root\"></div>" > "index.html.eex" # &>/dev/null
      # <lang> catch_error $? "No se pudo reemplazar el código en \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page/index.html.eex\""
      catch_error $? "Could not replace the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/templates/page/index.html.eex\" file"
    #--- 29 ---
      cd ../.. &>/dev/null
      # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web\""
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web\" directory could not be accessed"
    #--- 30 ---
      if [ "${KERNEL}" = "Darwin" ]; then
        sed -i "" $'/^\(end\)/i \
        \\\n  if Mix.env == :dev do\\\n    forward \"/graphiql\", Absinthe.Plug.GraphiQL,\\\n      schema: '"${MODULE}"$'.Graphql.Schema,\\\n      interface: :advanced,\\\n      context: %{pubsub: '"${MODULE}"$'.Endpoint}\\\n  end\\\n' router.ex &>/dev/null
      else
        sed -i $'/^\(end\)/i \
        \\\n  if Mix.env == :dev do\\\n    forward \"/graphiql\", Absinthe.Plug.GraphiQL,\\\n      schema: '"${MODULE}"$'.Graphql.Schema,\\\n      interface: :advanced,\\\n      context: %{pubsub: '"${MODULE}"$'.Endpoint}\\\n  end\\\n' router.ex &>/dev/null
      fi
      # <lang> catch_error $? "No se pudo agregar código en \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/router.ex\""
      catch_error $? "Could not add the code in \"${PROJECT_NAME}/lib/${PROJECT_NAME}_web/router.ex\" file"
    #--- 31 ---
      cd ../"${PROJECT_NAME}" &>/dev/null
      # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}\""
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}\" directory could not be accessed"
    #--- 32 ---
      mkdir graphql &>/dev/null
      # <lang> catch_error $? "No se pudo crear el directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\" directory"
    #--- 33 ---
      cd graphql &>/dev/null
      # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\""
      catch_error $? "The \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql\" directory could not be accessed"
    #--- 34 ---
      touch queries.ex &>/dev/null
      # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/queries.ex\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/queries.ex\" file"
    #--- 35 ---
      touch mutations.ex &>/dev/null
      # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/mutations.ex\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/mutations.ex\" file"
    #--- 36 ---
      touch subscriptions.ex &>/dev/null
      # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/subscriptions.ex\""
      catch_error $? "Unable to create \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/subscriptions.ex\" file"
    #--- 37 ---
      touch schema.ex &>/dev/null
      # <lang> catch_error $? "No se pudo crear el archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/schema.ex\""
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
      # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/queries.ex\""
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
      # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/mutations.ex\""
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
      # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/subscriptions.ex\""
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
      # <lang> catch_error $? "No se pudo agregar el contenido al archivo \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/schema.ex\""
      catch_error $? "Unable to add content to \"${PROJECT_NAME}/lib/${PROJECT_NAME}/graphql/schema.ex\" file"
  } & spinner
}
function task5 () {
  # <lang> display_message task "Compilando dependencias para Phoenix "
  display_message task "Compiling dependencies for Phoenix "
  {
  #--- 42 ---
    cd "${TARGET_PATH}/${PROJECT_NAME}" &>/dev/null
    # <lang> catch_error $? "No se pudo acceder al directorio \"${PROJECT_NAME}\""
    catch_error $? "The \"${PROJECT_NAME}\" directory could not be accessed"
  #--- 43 ---
    if [ "${KERNEL}" = "Darwin" ]; then
      sed -E -i "" $'s/{:cowboy, "~> [0-9]+\.[0-9]+"}/{:plug_cowboy, "~> 1.0"},\\\n      {:absinthe, "~> 1.4.13"},\\\n      {:absinthe_ecto, "~> 0.1.3"},\\\n      {:absinthe_plug, "~> 1.4.6"},\\\n      {:absinthe_phoenix, "~> 1.4.3"}/' mix.exs &>/dev/null
    else
      sed -i 's/{:cowboy, "~> [0-9][0-9]*\.[0-9][0-9]*"}/{:plug_cowboy, "~> 1.0"},\n      {:absinthe, "~> 1.4.13"},\n      {:absinthe_ecto, "~> 0.1.3"},\n      {:absinthe_plug, "~> 1.4.6"},\n      {:absinthe_phoenix, "~> 1.4.3"}/' mix.exs &>/dev/null
    fi
    # <lang> catch_error $? "No se pudo modificar las dependencias en \"${PROJECT_NAME}/mix.exs\""
    catch_error $? "The dependencies could not be modified in \"${PROJECT_NAME}/mix.exs\" file"
  #--- 44 ---
    mix deps.get &>/dev/null
    # <lang> catch_error $? "No se pudieron descargar las dependencias para Phoenix"
    catch_error $? "Unable to download dependencies for Phoenix"
  #--- 45 ---
    mix deps.compile &>/dev/null
    # <lang> catch_error $? "No se pudieron compilar las dependencias para Phoenix"
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
# <lang> display_message green "¡Se ha creado y configurado correctamente el proyecto!\n"
display_message green "The project has been created and configured correctly!"
printf "

 Go into your application by running:
 
   \e[1m$ cd ${PROJECT_NAME}\e[0m
 
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

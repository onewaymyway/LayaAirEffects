

/**
 * worker配置数据,运行时从服务器加载
 */
var workerConfig = {};
/**
 * service-worker的相对路径，用来计算主目录的路径
 * 运行时从workerConfig读取
 */
var myPath = "service-worker.js";
/**
 * 资源路径的根路径
 */
var urlBasePath = location.href.replace(myPath, "");
/**
 * Cache的标识符,所有的缓存放在这个标识符指定的缓存中
 * 运行时从workerConfig读取
 */
var CACHE_SIGN = "layaairtest";
/**
 * 当前应该获取的最新的文件本版数据文件的版本号
 * 运行时应该从加载的workerConfig中获取
 */
var fileVer = "1.1.1.1";
/**
 * 文件版本数据文件的相对路径
 */
var fileVerFilePath = "fileconfig.json";
/**
 * 文件版本数据
 */
var verdata = {};
/**
 * 开启调试功能
 */
var enableDebug = true;
/**
 * 调试信息输出端口
 */
var tarPort;

/**
 * 调试输出
 * 
 */
function debugTrace(msg) {
  if (!enableDebug || !tarPort) return;
  tarPort.postMessage({
    msg: "debugTrace",
    info: msg
  });
}

/**
 * 获取相对路径
 * 
 */
function getRelativePath(tPath) {
  return tPath.replace(urlBasePath, "");
}

/**
 * 获取不带url参数的相对路径
 * 
 */
function getPureRelativePath(tPath) {
  tPath = getRelativePath(tPath)
  if (tPath.indexOf("?") >= 0) {
    tPath = tPath.split("?")[0];
  }
  return tPath;
}
/**
 * 获取不带url参数的路径
 * 
 */
function getAdptPath(tPath) {
  if (tPath.indexOf("?") >= 0) {
    tPath = tPath.split("?")[0];
  }
  return tPath;
}
/**
 * 获取带版本号的路径
 * 
 */
function getVersionPath(tPath, version) {
  return tPath + "?v=" + version;
}

/**
 * 获取可用于缓存的Request对象
 * 
 */
function getAdptRequest(preRequest) {
  tPurePath = getPureRelativePath(preRequest.url);
  adptPath = getAdptPath(preRequest.url)
  adptPath += "?v=" + verdata[tPurePath];
  //adptRequest=preRequest.clone();
  //adptRequest.url=adptPath;
  adptRequest = new Request(adptPath);
  //adptRequest.method=adptPath.method;
  return adptRequest;
}

/**
 * 获取url中的版本信息
 * 
 */
function getUrlVer(tPath) {
  if (tPath.indexOf("?v=") > 0) {
    var tStr = tPath.split("?v=")[1];
    return tStr;

  }
  return "";
}

/**
 * 安装过程
 * 
 */
self.addEventListener('install',
  function (event) {
    console.log("install");
    self.skipWaiting();
    //event.waitUntil(

    //);
  });

/**
 * 更新workConfig
 * 根据workConfig更新数据
 * 
 */
function reloadConfigAndClearPre() {
  //加载worker配置文件
  return fetch("./workerconfig.json?ver=" + Math.random()).then(
    function (response) {
      return response.json();
    }
  ).then(
    function (data) {
      //解析worker配置文件
      console.log("load workerconfig success:", data);
      self.workerConfig = data;
      CACHE_SIGN = data["cacheSign"];
      myPath = data["workerPath"];
      urlBasePath = location.href.replace(myPath, "");
      fileVer = data["fileVer"]
      console.log("fileVer", fileVer);
      return data;
    }).then(function () {
      //获取文件版本信息数据

      //尝试在缓存中查找文件版本信息数据
      return caches.open(CACHE_SIGN).then(
        function (cache) {
          return cache.keys().then(function (requestlists) {
            var fileVerRQ;
            var tRQ;
            var tRelativePath;
            for (i = 0; i < requestlists.length; i++) {

              tRQ = requestlists[i];
              tRelativePath = getPureRelativePath(tRQ.url)
              if (tRelativePath == fileVerFilePath) {
                if (getUrlVer(tRQ.url) == fileVer) {
                  fileVerRQ = tRQ;
                } else {
                  cache.delete(tRQ);
                }

              }
            }
            var fileVerDataOK = false;
            if (fileVerRQ) {
              if (getUrlVer(fileVerRQ.url) == fileVer) {

                fileVerDataOK = true;
              }
            }
            // return fileVerDataOK;
            console.log("fileVerDataOK:", fileVerDataOK);
            if (fileVerDataOK) {
              //如果缓存中的版本数据是最新的 直接使用缓存数据
              console.log("use cached fileVerData");
              return cache.match(fileVerRQ.clone()).then
                (
                function (response) {
                  console.log("get cached fileVerData success");
                  return response.json();

                }
                )
            }
            //从网络加载最新的文件版本数据

            var fileConfigRq = new Request(getVersionPath(fileVerFilePath, fileVer));
            console.log("get new fileVerData", fileConfigRq.url);
            return fetch(fileConfigRq.clone()).then(
              function (response) {
                console.log("get new fileVerData success");
                cache.put(fileConfigRq.clone(), response.clone())
                return response.json();
              }
            )

          })
        }
      )
    }).then(
    function (data) {
      console.log("load fileConfig success:", data, JSON.stringify(data));
      verdata = data;
      verdata[fileVerFilePath]=fileVer;
      return data;
    }).then(
    function () {
      return caches.open(CACHE_SIGN).then(
        function (cache) {
          //更新cache中的文件,如果缓存的文件版本号不是最新的就删除缓存
          cache.keys().then(function (cacheNames) {
            return Promise.all(
              cacheNames.map(function (tRequest) {
                var cacheName = tRequest.url;
                //console.log("work with:", cacheName);
                if (cacheName.indexOf("?") > 0) {
                  tPureName = getPureRelativePath(cacheName);
                  tVer = getUrlVer(cacheName);
                  if ((tPureName == fileVerFilePath && tVer == fileVer) || (verdata[tPureName] && verdata[tPureName] == tVer)) {
                    // console.log('cache is ok:', cacheName);
                  } else {
                    console.log('cache is old:', cacheName);
                    return cache.delete(tRequest);
                  }
                }
              })
            );
          })
        }
      )

    }
    ).catch(
    function (e) {
      console.log("Oops, error");
    })
}

/**
 * 激活之后的处理
 * 
 */
self.addEventListener('activate', function (event) {
  console.log('activate:');
  event.waitUntil(
    reloadConfigAndClearPre()
  );
});


/**
 * 处理请求
 * 
 */
self.addEventListener('fetch', function (event) {
  debugTrace("fetch:" + event.request.url);
   //返回结果
  //return event.respondWith(
  //  goPass(event.request)
 // );
  
  //return goPass(event.request);
  var tPurePath = getPureRelativePath(event.request.url);
  if (verdata && verdata[tPurePath]) {
    //如果是受版本管理的文件,从缓存中查找
    tPromise = caches.open(CACHE_SIGN).then(function (cache) {
      return cache.match(getAdptRequest(event.request)).then(function (response) {
        if (response) {
          //缓存数据有效
          return response;
        }


        //没有缓存，从网络加载新的资源，并缓存
        return fetch(getAdptRequest(event.request)).then(function (response) {
          adptRequest = getAdptRequest(event.request);

          if (response.status < 400) {
            //如果加载到的数据有效
            tPurePath = getPureRelativePath(response.url);
            if (verdata && verdata[tPurePath]) {
              console.log('Caching', event.request.url, response.url);
              var cacheResponse = response.clone();
              cache.put(adptRequest.clone(), cacheResponse);
            } else {
              //理论上不该走到这里
            }

          } else {
            console.log('Not caching', adptRequest.url, response.url);
          }
          return response;
        });
      }).catch(function (error) {
        console.error('Error in fetch handler:', error);
        throw error;
      });
    })


  } else {

    //不受管理的请求
    tPromise = fetch(event.request.clone()).then(function (response) {
      return response;
    }).catch(function (error) {
      console.error('Error in fetch handler:', error);
      throw error;
    });
  }

  //返回结果
  event.respondWith(
    tPromise
  );
});

function goPass(trequest) {
  return fetch(trequest.clone()).then(function (response) {
    return response;
  })
}
/**
 * 处理消息
 * 
 */
self.addEventListener('message', function (event) {
  //console.log('Handling message event:', event);
  if (event.data) {
    switch (event.data.cmd) {
      case "reloadConfig"://刷新数据
        if (enableDebug) {
          tarPort = event.ports[0];
        }
        reloadConfigAndClearPre().then(
          function () {
            //刷新成功
            event.ports[0].postMessage({
              msg: "reloadSuccess",
              ver: fileVer
            });
          },
          function () {
            //刷新失败
            event.ports[0].postMessage({
              msg: "reloadFail",
              ver: fileVer
            });
          }
        );
        break;
    }
  }
});
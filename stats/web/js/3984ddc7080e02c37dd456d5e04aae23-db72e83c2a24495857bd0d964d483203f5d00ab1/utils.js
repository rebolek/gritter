window.utils = (function () {
  let utils = {}
  /**
   * Fetches a file and returns a promise of it's contents.
   * @param filename
   * @returns {Promise<string>}
   */
  utils.loadFile = async function loadFile (filename) {
    let result = await fetch(filename)
    return result.text()
  }

  /**
   * Simple object check.
   * @param item
   * @returns {boolean}
   */
  let isObject = utils.isObject = function isObject(item) {
    return (item && typeof item === 'object' && !Array.isArray(item));
  }

  /**
   * Deep merge two objects.
   * @param target
   * @param ...sources
   */
  utils.mergeDeep = function mergeDeep(target, ...sources) {
    if (!sources.length) return target;
    const source = sources.shift();

    if (isObject(target) && isObject(source)) {
      for (const key in source) {
        if (isObject(source[key])) {
          if (!target[key]) Object.assign(target, { [key]: {} });
          mergeDeep(target[key], source[key]);
        } else {
          Object.assign(target, { [key]: source[key] });
        }
      }
    }

    return mergeDeep(target, ...sources);
  }

  utils.identity = function identity (x) {
    return x
  }

  utils.prop = function prop (name) {
    return function (object) {
      return object[name]
    }
  }

  utils.compose = function compose (f, g) {
    return function (...args) {
      return f(g(...args))
    }
  }

  utils.withProp = function withProp (name, fn) {
    return function (object) {
      let newObject = Object.assign({}, object)

      newObject[name] = fn(object[name])

      return newObject
    }
  }

  utils.propMap = function withProp (name, fn) {
    return function (object) {
      return fn(object[name])
    }
  }

  utils.partition = function partition (collection, predicate) {
    let a = []
    let b = []

    collection.forEach(element => {
      if (predicate(element)) {
        a.push(element)
      } else {
        b.push(element)
      }
    })

    return [ a, b ]
  }

  return utils
})()

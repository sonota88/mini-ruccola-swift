Swift port of [Mini Ruccola (vm2gol-v2)](https://github.com/sonota88/vm2gol-v2) compiler

---

```
  $ swift -version
Swift version 6.0.2 (swift-6.0.2-RELEASE)
Target: x86_64-unknown-linux-gnu
```

```
git clone --recursive https://github.com/sonota88/mini-ruccola-swift.git
cd mini-ruccola-swift

./docker.sh build
./test.sh all
```

```
  $ LANG=C wc -l main.swift mrcl_*.swift lib/{types,utils,json}.swift
   14 main.swift
  341 mrcl_codegen.swift
   54 mrcl_lexer.swift
  316 mrcl_parser.swift
  132 lib/types.swift
   83 lib/utils.swift
   98 lib/json.swift
 1038 total

  # main part
  $ LANG=C wc -l mrcl_*.swift
  341 mrcl_codegen.swift
   54 mrcl_lexer.swift
  316 mrcl_parser.swift
  711 total

  # main part / excluding comment lines
  $ cat mrcl_*.swift | grep -v '^ *//' | wc -l
674
```

# action: deploy charm services

```deps
shared/deploydeploy
```

```always
```

```install
if [ $SHERMAN_ENV = charm ]; then
    echo "Running deploydeploy for charm services..."
    cd $SHERMAN_DIR/deploy
    $SHERMAN_DIR/bin/deploydeploy deploy -s charm
fi
```

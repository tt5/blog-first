# page2

@@@
<div x-data="{ open: false }">
  <button @click="open = ! open">Expand</button>
  <template x-if="open">
    <div
  x-data="{a: null}"
  x-init="a = await (await fetch('/comp1')).text()"
  x-html="a"
    >
  </template>
</div>
<div
  x-data="myfun"
  x-bind="some"
>
</div>
@@@



<template>
  <div class="itinerary-item">
    <div class="itinerary-item-line"></div>
    <div
      v-for="leg in itinerary.legs"
      :key="leg.startTime"
      :style="{
        position: 'relative',
      }"
    >
      <div
        :style="{
          position: 'absolute',
          backgroundColor: leg.transitLeg ? '#d11' : '#aaa',
          left: `${
            100 *
            ((leg.startTime - earliestStart) / (latestArrival - earliestStart))
          }%`,
          right: `${Math.round(
            100 *
              ((latestArrival - leg.endTime) / (latestArrival - earliestStart))
          )}%`,
          height: '3em',
          top: '-2em',
          marginLeft: '0.2em',
          marginRight: '0.2em',
          borderRadius: '0.5em',
        }"
      >
        <q-icon
          v-if="
            leg.mode === 'BUS' &&
            (leg.endTime - leg.startTime) / (latestArrival - earliestStart) >
              0.1
          "
          name="directions_bus"
          color="black"
          size="sm"
          :style="{
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
          }"
        ></q-icon>
        <q-icon
          v-if="
            leg.mode === 'WALK' &&
            (leg.endTime - leg.startTime) / (latestArrival - earliestStart) >
              0.1
          "
          name="directions_walk"
          color="black"
          size="sm"
          :style="{
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
          }"
        ></q-icon>
        <q-icon
          v-if="
            (leg.mode === 'TRAIN' || leg.mode === 'TRAM') &&
            (leg.endTime - leg.startTime) / (latestArrival - earliestStart) >
              0.1
          "
          name="directions_train"
          color="black"
          size="sm"
          :style="{
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
          }"
        ></q-icon>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'TransitTimeline',
  props: ['itinerary', 'earliestStart', 'latestArrival'],
});
</script>

<script lang="ts">
  import { onMount } from 'svelte';

  // Reference na video element s TS typem
  let videoElement: HTMLVideoElement;
  
  // Stavové proměnné
  let paused: boolean = true;
  let currentTime: number = 0;
  let duration: number = 0;
  let volume: number = 1;
  let showControls: boolean = true;
  let controlsTimeout: ReturnType<typeof setTimeout>;

  // Formátování času (0:00)
  const formatTime = (seconds: number): string => {
    if (isNaN(seconds)) return "0:00";
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  // Klávesové zkratky
  const handleKeyDown = (e: KeyboardEvent): void => {
    // Zabráníme spuštění zkratek, pokud uživatel píše do inputu
    if (e.target instanceof HTMLInputElement) return;

    switch(e.key.toLowerCase()) {
      case ' ': 
        e.preventDefault();
        paused = !paused; 
        break;
      case 'f': 
        if (!document.fullscreenElement) {
          videoElement.requestFullscreen();
        } else {
          document.exitFullscreen();
        }
        break;
      case 'm':
        volume = volume === 0 ? 0.5 : 0;
        break;
      case 'arrowright': 
        currentTime = Math.min(currentTime + 5, duration); 
        break;
      case 'arrowleft': 
        currentTime = Math.max(currentTime - 5, 0); 
        break;
    }
  };

  const resetTimer = (): void => {
    showControls = true;
    clearTimeout(controlsTimeout);
    if (!paused) {
      controlsTimeout = setTimeout(() => showControls = false, 2500);
    }
  };

  // Úklid po zničení komponenty
  onMount(() => {
    return () => clearTimeout(controlsTimeout);
  });
</script>

<svelte:window on:keydown={handleKeyDown} />

<div 
  class="relative w-full h-dvh mx-auto aspect-video bg-black overflow-hidden shadow-2xl group"
  on:mousemove={resetTimer}
  role="region"
  aria-label="Video Player"
>
  <video
    bind:this={videoElement}
    bind:paused
    bind:currentTime
    bind:duration
    bind:volume
    on:click={() => paused = !paused}
    src="https://www.w3schools.com/html/mov_bbb.mp4" 
    class="w-full h-full cursor-pointer"
  >
    <track kind="captions" />
  </video>

  <div 
    class="absolute inset-0 flex flex-col justify-end transition-opacity duration-500 bg-linear-to-t from-black/80 via-transparent to-transparent
    {showControls || paused ? 'opacity-100' : 'opacity-0'}"
  >
    <div class="p-4 w-full space-y-4">
      
      <div class="relative group/progress h-2 w-full flex items-center">
        <input
          type="range"
          min="0"
          max={duration}
          step="0.01"
          bind:value={currentTime}
          class="absolute w-full h-1 accent-blue-500 bg-white/20 rounded-full appearance-none cursor-pointer group-hover/progress:h-2 transition-all"
        />
      </div>

      <div class="flex items-center justify-between text-white">
        <div class="flex items-center gap-5">
          <button 
            on:click={() => paused = !paused} 
            class="hover:text-blue-400 transition-colors transform active:scale-90"
          >
            {#if paused}
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            {:else}
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
            {/if}
          </button>

          <div class="text-sm font-mono tracking-tighter">
            <span class="text-white">{formatTime(currentTime)}</span>
            <span class="text-white/40 mx-1">/</span>
            <span class="text-white/60">{formatTime(duration)}</span>
          </div>

          <div class="flex items-center gap-2 ml-2">
             <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5L6 9H2v6h4l5 4V5z"></path><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"></path></svg>
             <input 
              type="range" min="0" max="1" step="0.01" 
              bind:value={volume}
              class="w-16 h-1 accent-white opacity-60 hover:opacity-100 transition-opacity"
            />
          </div>
        </div>

        <button 
          on:click={() => videoElement.requestFullscreen()}
          class="p-2 hover:bg-white/10 rounded-full transition-colors"
          aria-label="Fullscreen"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"/></svg>
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  /* Odstranění nativních ovládacích prvků v režimu celé obrazovky */
  video::-webkit-media-controls {
    display: none !important;
  }
  
  /* Reset vzhledu slideru pro různé prohlížeče */
  input[type="range"] {
    -webkit-appearance: none;
    appearance: none;
    background: rgba(255, 255, 255, 0.2);
  }
  
  input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    height: 12px;
    width: 12px;
    background: #3b82f6; /* blue-500 */
    border-radius: 50%;
    cursor: pointer;
  }
</style>
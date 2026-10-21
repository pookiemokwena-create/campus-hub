"""Render supplied illustrated assets and selected-voice WAVs to a motion comic.
Requires: pip install imageio-ffmpeg pillow
Captions are estimated from sentence length, not forced-aligned.
"""
from pathlib import Path
import re, wave, subprocess, math
import imageio_ffmpeg
from PIL import Image, ImageOps
ROOT = Path(__file__).resolve().parent
WORK = ROOT/'work'; WORK.mkdir(exist_ok=True)
OUT = ROOT/'exports'; OUT.mkdir(exist_ok=True)
FF = imageio_ffmpeg.get_ffmpeg_exe()
SPEED=1.13
texts=(ROOT/'narration.txt').read_text().split('===')
images=['kitchen','watch','street','sky']
def stamp(s):
    ms=round(s*1000); h,ms=divmod(ms,3600000); m,ms=divmod(ms,60000); sec,ms=divmod(ms,1000)
    return f'{h:02}:{m:02}:{sec:02},{ms:03}'
allcaps=[]; offset=0
for i,(text,img) in enumerate(zip(texts,images),1):
    audio=ROOT/'audio'/f'{i:02}.wav'
    with wave.open(str(audio)) as w: dur=w.getnframes()/w.getframerate()/SPEED
    # Pre-scale once so zoompan never stretches the original composition.
    im=ImageOps.fit(Image.open(ROOT/'assets'/f'{img}.jpg').convert('RGB'),(1920,1080))
    im.save(WORK/f'{i}.jpg')
    sentences=re.split(r'(?<=[.!?])\s+',text.strip())
    weights=[len(s.split())+1.8 for s in sentences]; total=sum(weights)
    t=0; caps=[]
    for s,wt in zip(sentences,weights):
        end=t+dur*wt/total
        caps.append(f'{len(caps)+1}\n{stamp(t)} --> {stamp(end)}\n{s}\n')
        allcaps.append(f'{len(allcaps)+1}\n{stamp(t+offset)} --> {stamp(end+offset)}\n{s}\n')
        t=end
    sub=WORK/f'{i}.srt'; sub.write_text('\n'.join(caps))
    frames=math.ceil(dur*24)
    vf=(f"zoompan=z='1+0.000035*on':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d={frames}:s=1280x720:fps=24,"
        f"fade=t=in:st=0:d=0.7,fade=t=out:st={dur-0.7}:d=0.7,"
        f"subtitles={sub}:force_style='FontName=DejaVu Sans,FontSize=21,PrimaryColour=&H00FFFFFF,OutlineColour=&H00101010,BorderStyle=1,Outline=2,Shadow=1,MarginV=35,MarginL=45,MarginR=45'")
    cmd=[FF,'-y','-i',str(WORK/f'{i}.jpg'),'-i',str(audio),'-vf',vf,'-af',f'atempo={SPEED}',
         '-t',str(dur),'-c:v','libx264','-preset','fast','-crf','24','-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-movflags','+faststart',str(WORK/f'{i}.mp4')]
    subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL,stderr=(WORK/f'{i}.log').open('w'))
    offset+=dur
    print(f'Scene {i} complete: {dur:.1f}s',flush=True)
(ROOT/'exports'/'episode-01.srt').write_text('\n'.join(allcaps))
concat=WORK/'concat.txt'; concat.write_text('\n'.join(f"file '{WORK}/{i}.mp4'" for i in range(1,5)))
subprocess.run([FF,'-y','-f','concat','-safe','0','-i',str(concat),'-c','copy','-movflags','+faststart',str(OUT/'after-the-last-bell-episode-01.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=(WORK/'concat.log').open('w'))
print(f'Finished: {offset:.1f} seconds',flush=True)

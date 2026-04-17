#ifndef __MEMORY_BUFFER_MQH__
#define __MEMORY_BUFFER_MQH__

class CMemoryBuffer
{
private:
   string buffer[];
   int lineCount;
   ulong bufferSize;
   int maxLines;
   ulong maxSize;

public:
   CMemoryBuffer()
   {
      lineCount = 0;
      bufferSize = 0;
      maxLines = 1000;
      maxSize = 5120;
      ArrayResize(buffer, 0);
   }

   ~CMemoryBuffer()
   {
      Clear();
   }

   void Append(string line)
   {
      int newSize = lineCount + 1;
      ArrayResize(buffer, newSize);
      buffer[lineCount] = line;
      lineCount++;
      bufferSize += StringLen(line) * 2 + 2;
   }

   ulong GetSize()
   {
      return bufferSize;
   }

   int GetLineCount()
   {
      return lineCount;
   }

   bool ShouldFlush()
   {
      return (bufferSize >= maxSize) || (lineCount >= maxLines);
   }

   string GetContent()
   {
      string content = "";
      for(int i = 0; i < lineCount; i++)
      {
         content += buffer[i];
         if(i < lineCount - 1)
            content += "\n";
      }
      return content;
   }

   void Clear()
   {
      ArrayFree(buffer);
      lineCount = 0;
      bufferSize = 0;
   }
};

#endif